#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/foundry-env.sh"
: "${ARC_MAINNET_RPC_URL:?Set ARC_MAINNET_RPC_URL}"
: "${ARC_MAINNET_CHAIN_ID:?Set ARC_MAINNET_CHAIN_ID}"
: "${ARC_MAINNET_USDC_ADDRESS:?Set ARC_MAINNET_USDC_ADDRESS}"
: "${ARC_MAINNET_EXPLORER_URL:?Set ARC_MAINNET_EXPLORER_URL}"
: "${ARC_MAINNET_PROOFPAY_ADDRESS:?Set ARC_MAINNET_PROOFPAY_ADDRESS after deployment}"
: "${ARC_MAINNET_CREATOR_PRIVATE_KEY:?ARC_MAINNET_CREATOR_PRIVATE_KEY is required}"
: "${ARC_MAINNET_WORKER_PRIVATE_KEY:?ARC_MAINNET_WORKER_PRIVATE_KEY is required}"

[ "${ARC_MAINNET_CHAIN_ID}" != "5042002" ] || { echo "Refusing: Arc Testnet chain ID supplied." >&2; exit 1; }
[[ "${ARC_MAINNET_RPC_URL,,}" != *testnet* && "${ARC_MAINNET_EXPLORER_URL,,}" != *testnet* ]] || { echo "Refusing: Testnet endpoint supplied." >&2; exit 1; }
chain_id="$(cast chain-id --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${chain_id}" = "${ARC_MAINNET_CHAIN_ID}" ] || { echo "Unexpected chain ID: ${chain_id}." >&2; exit 1; }
code="$(cast code "${ARC_MAINNET_USDC_ADDRESS}" --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${code}" != "0x" ] || { echo "Mainnet USDC bytecode is missing." >&2; exit 1; }
decimals="$(cast call "${ARC_MAINNET_USDC_ADDRESS}" 'decimals()(uint8)' --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${decimals}" = "6" ] || { echo "Expected six-decimal USDC, got ${decimals}." >&2; exit 1; }

amount_raw="$(AMOUNT_USDC="${ARC_MAINNET_SMOKE_AMOUNT_USDC:-0.001}" node -e '
const value=process.env.AMOUNT_USDC; if(!/^\d+(\.\d{1,6})?$/.test(value)) process.exit(1); const [whole,fraction=""] = value.split("."); console.log(BigInt(whole)*1000000n+BigInt((fraction+"000000").slice(0,6)));
')"
[ "${amount_raw}" -gt 0 ] || { echo "Smoke amount must be positive." >&2; exit 1; }
echo "Running tiny real-USDC lifecycle (${ARC_MAINNET_SMOKE_AMOUNT_USDC:-0.001} USDC = ${amount_raw} raw units)."

log_file="$(mktemp)"
trap 'rm -f "${log_file}"' EXIT
if ! (cd "${ROOT_DIR}/contracts" && forge script script/MainnetSmoke.s.sol:MainnetSmoke --sig 'run(address,address,uint256)' "${ARC_MAINNET_PROOFPAY_ADDRESS}" "${ARC_MAINNET_USDC_ADDRESS}" "${amount_raw}" --rpc-url "${ARC_MAINNET_RPC_URL}" --private-key "${ARC_MAINNET_CREATOR_PRIVATE_KEY}" --broadcast >"${log_file}" 2>&1); then
  sed -E 's/(private[-_ ]key|0x[0-9a-fA-F]{64})/[REDACTED]/Ig' "${log_file}" | tail -60 >&2
  exit 1
fi

task_id="$(sed -nE 's/.*Smoke task ID[[:space:]]+([0-9]+).*/\1/p' "${log_file}" | tail -1)"
echo "Mainnet smoke lifecycle passed."
[ -n "${task_id}" ] && echo "Task ID: ${task_id}" || echo "Task ID: inspect the confirmed lifecycle transaction logs."
echo "ProofPay explorer: ${ARC_MAINNET_EXPLORER_URL%/}/address/${ARC_MAINNET_PROOFPAY_ADDRESS}"
deployment_file="${ROOT_DIR}/contracts/broadcast/MainnetSmoke.s.sol/${chain_id}/run-latest.json"
if [ -f "${deployment_file}" ]; then
  EXPLORER="${ARC_MAINNET_EXPLORER_URL%/}" node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); for(const t of d.transactions||[]) if(t.hash) console.log(process.env.EXPLORER+"/tx/"+t.hash);' "${deployment_file}"
fi
