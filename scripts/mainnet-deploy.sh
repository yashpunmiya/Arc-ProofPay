#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/foundry-env.sh"
: "${ARC_MAINNET_RPC_URL:?Set ARC_MAINNET_RPC_URL}"
: "${ARC_MAINNET_CHAIN_ID:?Set ARC_MAINNET_CHAIN_ID}"
: "${ARC_MAINNET_USDC_ADDRESS:?Set ARC_MAINNET_USDC_ADDRESS}"
: "${ARC_MAINNET_EXPLORER_URL:?Set ARC_MAINNET_EXPLORER_URL}"
: "${ARC_MAINNET_PRIVATE_KEY:?ARC_MAINNET_PRIVATE_KEY is required}"
[ "${CONFIRM_ARC_MAINNET_DEPLOYMENT:-}" = "DEPLOY_PROOFPAY_WITH_REAL_USDC" ] || {
  echo "Refusing: set CONFIRM_ARC_MAINNET_DEPLOYMENT=DEPLOY_PROOFPAY_WITH_REAL_USDC" >&2
  exit 1
}

metadata="${ROOT_DIR}/deployments/arc-mainnet.json"
if [ -f "${metadata}" ] && [ "${ALLOW_MAINNET_DEPLOYMENT_OVERWRITE:-}" != "YES_I_UNDERSTAND" ]; then
  echo "Refusing to overwrite ${metadata}. Set ALLOW_MAINNET_DEPLOYMENT_OVERWRITE=YES_I_UNDERSTAND only for an intentional replacement." >&2
  exit 1
fi
if [ "${ARC_MAINNET_CHAIN_ID}" = "5042002" ] || [[ "${ARC_MAINNET_RPC_URL,,}" == *testnet* || "${ARC_MAINNET_EXPLORER_URL,,}" == *testnet* ]]; then
  echo "Refusing: Mainnet configuration points to Arc Testnet." >&2
  exit 1
fi

chain_id="$(cast chain-id --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${chain_id}" = "${ARC_MAINNET_CHAIN_ID}" ] || { echo "Unexpected chain ID: ${chain_id}." >&2; exit 1; }
code="$(cast code "${ARC_MAINNET_USDC_ADDRESS}" --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${code}" != "0x" ] || { echo "Mainnet USDC bytecode is missing." >&2; exit 1; }
decimals="$(cast call "${ARC_MAINNET_USDC_ADDRESS}" 'decimals()(uint8)' --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${decimals}" = "6" ] || { echo "Expected six-decimal USDC, got ${decimals}." >&2; exit 1; }

deployer="$(cast wallet address --private-key "${ARC_MAINNET_PRIVATE_KEY}")"
if [ -n "${ARC_MAINNET_DEPLOYER_ADDRESS:-}" ] && [ "${deployer,,}" != "${ARC_MAINNET_DEPLOYER_ADDRESS,,}" ]; then
  echo "Refusing: private-key address does not match ARC_MAINNET_DEPLOYER_ADDRESS." >&2
  exit 1
fi
echo "WARNING: this deploys ProofPay with real Arc Mainnet USDC."
echo "Deployer: ${deployer}"

log_file="$(mktemp)"
trap 'rm -f "${log_file}"' EXIT
if ! (cd "${ROOT_DIR}/contracts" && forge script script/Deploy.s.sol:DeployProofPay --sig 'run(address)' "${ARC_MAINNET_USDC_ADDRESS}" --rpc-url "${ARC_MAINNET_RPC_URL}" --private-key "${ARC_MAINNET_PRIVATE_KEY}" --broadcast >"${log_file}" 2>&1); then
  sed -E 's/(private[-_ ]key|0x[0-9a-fA-F]{64})/[REDACTED]/Ig' "${log_file}" | tail -60 >&2
  exit 1
fi

deployment_file="${ROOT_DIR}/contracts/broadcast/Deploy.s.sol/${chain_id}/run-latest.json"
[ -f "${deployment_file}" ] || { echo "Deployment broadcast metadata not found." >&2; exit 1; }
readarray -t deployment_values < <(node -e '
const fs=require("fs"); const data=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
const tx=(data.transactions||[]).find((x)=>x.transactionType==="CREATE"&&x.contractName==="ProofPay");
if(!tx||!tx.contractAddress||!tx.hash) process.exit(1); console.log(tx.contractAddress); console.log(tx.hash);
' "${deployment_file}")
contract_address="${deployment_values[0]}"
deployment_tx="${deployment_values[1]}"
deployed_code="$(cast code "${contract_address}" --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${deployed_code}" != "0x" ] || { echo "Deployed ProofPay bytecode is missing." >&2; exit 1; }
configured_usdc="$(cast call "${contract_address}" 'usdc()(address)' --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${configured_usdc,,}" = "${ARC_MAINNET_USDC_ADDRESS,,}" ] || { echo "Deployed ProofPay points at unexpected USDC." >&2; exit 1; }

mkdir -p "${ROOT_DIR}/deployments"
METADATA="${metadata}" CONTRACT_ADDRESS="${contract_address}" DEPLOYMENT_TX_HASH="${deployment_tx}" ARC_MAINNET_CHAIN_ID="${ARC_MAINNET_CHAIN_ID}" ARC_MAINNET_USDC_ADDRESS="${ARC_MAINNET_USDC_ADDRESS}" ARC_MAINNET_EXPLORER_URL="${ARC_MAINNET_EXPLORER_URL}" node -e '
const fs=require("fs"); const out={network:"arc-mainnet",chainId:Number(process.env.ARC_MAINNET_CHAIN_ID),contractAddress:process.env.CONTRACT_ADDRESS,deploymentTxHash:process.env.DEPLOYMENT_TX_HASH,usdcAddress:process.env.ARC_MAINNET_USDC_ADDRESS,explorerUrl:process.env.ARC_MAINNET_EXPLORER_URL,deployedAt:new Date().toISOString()}; fs.writeFileSync(process.env.METADATA,JSON.stringify(out,null,2)+"\n");
'

echo "ProofPay Mainnet deployment verified."
echo "Contract: ${contract_address}"
echo "Deployment transaction: ${deployment_tx}"
echo "Contract explorer: ${ARC_MAINNET_EXPLORER_URL%/}/address/${contract_address}"
echo "Transaction explorer: ${ARC_MAINNET_EXPLORER_URL%/}/tx/${deployment_tx}"
echo "Metadata: ${metadata}"
