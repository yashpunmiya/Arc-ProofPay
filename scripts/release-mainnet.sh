#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_RELEASE_COMMIT="${EXPECTED_RELEASE_COMMIT:-$(git -C "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" rev-parse HEAD)}"
source "${ROOT_DIR}/scripts/load-mainnet-env.sh"
source "${ROOT_DIR}/scripts/foundry-env.sh"

if [ ! -f "${ROOT_DIR}/.env.mainnet.local" ]; then
  echo "Mainnet secrets are not configured. Run ./scripts/setup-mainnet-secrets.sh first." >&2
  exit 1
fi
: "${ARC_MAINNET_PRIVATE_KEY:?Mainnet deployer key missing; run setup-mainnet-secrets.sh}"
: "${ARC_MAINNET_WORKER_PRIVATE_KEY:?Mainnet worker key missing; run setup-mainnet-secrets.sh}"
: "${CONFIRM_ARC_MAINNET_DEPLOYMENT:?Set the explicit deployment confirmation.}"
[ "${CONFIRM_ARC_MAINNET_DEPLOYMENT}" = "DEPLOY_PROOFPAY_WITH_REAL_USDC" ] || { echo "Refusing: invalid deployment confirmation." >&2; exit 1; }

status="$(git -C "${ROOT_DIR}" status --short)"
[ -z "${status}" ] || { echo "Refusing: repository is not clean:"; echo "${status}"; exit 1; }
commit="$(git -C "${ROOT_DIR}" rev-parse HEAD)"
[ "${commit}" = "${EXPECTED_RELEASE_COMMIT}" ] || { echo "Refusing: expected release ${EXPECTED_RELEASE_COMMIT}, found ${commit}." >&2; exit 1; }
[ "$(git -C "${ROOT_DIR}" show -s --format=%s HEAD)" = "chore: harden ProofPay for release" ] || { echo "Refusing: HEAD is not the hardened ProofPay release commit." >&2; exit 1; }

deployer="$(cast wallet address --private-key "${ARC_MAINNET_PRIVATE_KEY}")"
worker="$(cast wallet address --private-key "${ARC_MAINNET_WORKER_PRIVATE_KEY}")"
[ "${deployer,,}" = "${ARC_MAINNET_DEPLOYER_ADDRESS,,}" ] || { echo "Refusing: deployer key/address mismatch." >&2; exit 1; }
[ "${worker,,}" != "${deployer,,}" ] || { echo "Refusing: worker must differ from deployer." >&2; exit 1; }

echo "Running full pre-broadcast test suite..."
(cd "${ROOT_DIR}" && ./scripts/test-all.sh)
(cd "${ROOT_DIR}" && ./scripts/mainnet-preflight.sh)

rpc="${ARC_MAINNET_RPC_URL}"
native_balance="$(cast balance "${deployer}" --rpc-url "${rpc}")"
usdc_raw="$(cast call "${ARC_MAINNET_USDC_ADDRESS}" 'balanceOf(address)(uint256)' "${deployer}" --rpc-url "${rpc}")"
gas_price="$(cast gas-price --rpc-url "${rpc}")"
worker_balance="$(cast balance "${worker}" --rpc-url "${rpc}")"
planned_worker_funding="$(GAS_PRICE="${gas_price}" node -e 'const p=BigInt(process.env.GAS_PRICE); console.log((p*300000n*3n).toString())')"

estimate_log="$(mktemp)"
trap 'rm -f "${estimate_log}"' EXIT
(cd "${ROOT_DIR}/contracts" && forge script script/Deploy.s.sol:DeployProofPay --sig 'run(address)' "${ARC_MAINNET_USDC_ADDRESS}" --rpc-url "${rpc}" --private-key "${ARC_MAINNET_PRIVATE_KEY}" >"${estimate_log}" 2>&1) || { sed -E 's/(private[-_ ]key|0x[0-9a-fA-F]{64})/[REDACTED]/Ig' "${estimate_log}" | tail -60 >&2; exit 1; }
estimated_fee="$(grep -E 'Estimated amount required:' "${estimate_log}" | tail -1 | sed -E 's/.*Estimated amount required:[[:space:]]*//')"
[ -n "${estimated_fee}" ] || { echo "Refusing: deployment fee estimate was unavailable." >&2; exit 1; }
smoke_raw=1
echo "PRE-BROADCAST SUMMARY"
echo "Source commit: ${commit}"
echo "Deployer: ${deployer}"
echo "Deployer native balance: ${native_balance}"
echo "Deployer USDC balance: ${usdc_raw} raw (${usdc_raw} / 1e6 USDC)"
echo "Worker: ${worker}"
echo "Worker native balance: ${worker_balance}"
echo "Chain ID: ${ARC_MAINNET_CHAIN_ID}"
echo "USDC: ${ARC_MAINNET_USDC_ADDRESS} (6 decimals)"
echo "Deployment estimated fee: ${estimated_fee}"
echo "Planned worker funding (wei): ${planned_worker_funding}"
echo "Smoke bounty: 0.000001 USDC (raw amount ${smoke_raw}, decimals 6)"
echo "Confirmation accepted; broadcasting exactly one deployment."

(cd "${ROOT_DIR}" && ./scripts/mainnet-deploy.sh)
contract_address="$(node -e 'const fs=require("fs"); console.log(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).contractAddress)' "${ROOT_DIR}/deployments/arc-mainnet.json")"
PROOFPAY_ADDRESS="${contract_address}" ENV_FILE="${ROOT_DIR}/.env.mainnet.local" node -e 'const fs=require("fs"); const p=process.env.ENV_FILE; let s=fs.readFileSync(p,"utf8"); if(/^ARC_MAINNET_PROOFPAY_ADDRESS=.*$/m.test(s)) s=s.replace(/^ARC_MAINNET_PROOFPAY_ADDRESS=.*$/m,"ARC_MAINNET_PROOFPAY_ADDRESS="+process.env.PROOFPAY_ADDRESS); else s+="\nARC_MAINNET_PROOFPAY_ADDRESS="+process.env.PROOFPAY_ADDRESS+"\n"; fs.writeFileSync(p,s,{mode:0o600});'
source "${ROOT_DIR}/scripts/load-mainnet-env.sh"
[ -n "${ARC_MAINNET_PROOFPAY_ADDRESS:-}" ] || { echo "Deployment did not produce a configured address." >&2; exit 1; }

worker_funding_tx="not required"
if [ "${worker_balance}" = "0" ] || [ "${worker_balance}" -lt "${planned_worker_funding}" ]; then
  funding="$(node -e 'const p=BigInt(process.argv[1]),b=BigInt(process.argv[2]); console.log(p>b?p-b:0n)' "${planned_worker_funding}" "${worker_balance}")"
  if [ "${funding}" -gt 0 ]; then
    worker_funding_tx="$(cast send "${worker}" --value "${funding}" --private-key "${ARC_MAINNET_PRIVATE_KEY}" --rpc-url "${rpc}" --json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).transactionHash))')"
  fi
fi
echo "Worker funding transaction: ${worker_funding_tx}"

smoke_log="$(mktemp)"
if ! (cd "${ROOT_DIR}" && ./scripts/mainnet-smoke.sh >"${smoke_log}" 2>&1); then
  sed -E 's/(private[-_ ]key|0x[0-9a-fA-F]{64})/[REDACTED]/Ig' "${smoke_log}" | tail -80 >&2
  exit 1
fi
task_id="$(sed -nE 's/.*Task ID:[[:space:]]*([0-9]+).*/\1/p' "${smoke_log}" | tail -1)"
[ -n "${task_id}" ] || { echo "Smoke completed without a task ID." >&2; exit 1; }

RPC="${rpc}" PROOFPAY="${ARC_MAINNET_PROOFPAY_ADDRESS}" USDC="${ARC_MAINNET_USDC_ADDRESS}" CREATOR="${deployer}" WORKER="${worker}" TASK_ID="${task_id}" node - <<'NODE'
const { createPublicClient, http, parseAbi, getAddress } = require("viem");
const c = createPublicClient({ transport: http(process.env.RPC) });
const abi = parseAbi(["function getTask(uint256) view returns (uint256,address,address,uint256,uint64,uint64,uint64,uint64,uint8,string,string,string)","function usdc() view returns (address)"]);
(async()=>{ const t=await c.readContract({address:getAddress(process.env.PROOFPAY),abi,functionName:"getTask",args:[BigInt(process.env.TASK_ID)]}); const token=await c.readContract({address:getAddress(process.env.PROOFPAY),abi,functionName:"usdc"}); if(token.toLowerCase()!==process.env.USDC.toLowerCase()||t[1].toLowerCase()!==process.env.CREATOR.toLowerCase()||t[2].toLowerCase()!==process.env.WORKER.toLowerCase()||t[3]!==1n||t[8]!==3) throw new Error("independent smoke verification failed"); console.log(`Independent verification passed: task ${process.env.TASK_ID}, COMPLETED, amount 1, payout worker ${t[2]}`); })().catch(e=>{console.error(e.message);process.exit(1)});
NODE

cat >"${ROOT_DIR}/.env.production.local" <<EOF
NEXT_PUBLIC_ARC_ENV=mainnet
NEXT_PUBLIC_ARC_MAINNET_RPC_URL=${ARC_MAINNET_RPC_URL}
NEXT_PUBLIC_PROOFPAY_ADDRESS=${ARC_MAINNET_PROOFPAY_ADDRESS}
EOF
chmod 600 "${ROOT_DIR}/.env.production.local"
(cd "${ROOT_DIR}" && pnpm lint && pnpm typecheck && pnpm test && pnpm build && ./scripts/check-secrets.sh)
echo "Mainnet deployment and smoke verification completed. Review generated metadata/docs before committing." 
