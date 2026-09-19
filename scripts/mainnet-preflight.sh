#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/load-mainnet-env.sh"
source "${ROOT_DIR}/scripts/foundry-env.sh"

echo "--- git ---"
git -C "${ROOT_DIR}" rev-parse --short HEAD 2>/dev/null || echo "No commit yet"
git -C "${ROOT_DIR}" status --short
echo "--- production build ---"
(cd "${ROOT_DIR}" && pnpm build)

: "${ARC_MAINNET_RPC_URL:?Set ARC_MAINNET_RPC_URL to the official Arc Mainnet RPC}"
: "${ARC_MAINNET_CHAIN_ID:?Set ARC_MAINNET_CHAIN_ID from official Arc documentation}"
: "${ARC_MAINNET_USDC_ADDRESS:?Set ARC_MAINNET_USDC_ADDRESS from official Arc documentation}"
: "${ARC_MAINNET_EXPLORER_URL:?Set ARC_MAINNET_EXPLORER_URL from official Arc documentation}"
: "${ARC_MAINNET_DEPLOYER_ADDRESS:?Set ARC_MAINNET_DEPLOYER_ADDRESS (public address only)}"

if [ "${ARC_MAINNET_CHAIN_ID}" = "5042002" ]; then
  echo "Refusing: ARC_MAINNET_CHAIN_ID is Arc Testnet (5042002)." >&2
  exit 1
fi
if [[ "${ARC_MAINNET_RPC_URL,,}" == *testnet* || "${ARC_MAINNET_EXPLORER_URL,,}" == *testnet* ]]; then
  echo "Refusing: Mainnet configuration contains a Testnet endpoint." >&2
  exit 1
fi
if [ -n "${ARC_MAINNET_PROOFPAY_ADDRESS:-}" ]; then
  echo "Refusing: ARC_MAINNET_PROOFPAY_ADDRESS must remain empty before first deployment." >&2
  exit 1
fi
if [ -n "${NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS:-}" ] && [ "${NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS,,}" = "${ARC_MAINNET_PROOFPAY_ADDRESS,,}" ]; then
  echo "Refusing: Mainnet ProofPay configuration matches the Testnet address." >&2
  exit 1
fi

chain_id="$(cast chain-id --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${chain_id}" = "${ARC_MAINNET_CHAIN_ID}" ] || { echo "Unexpected chain ID: ${chain_id} (expected ${ARC_MAINNET_CHAIN_ID})." >&2; exit 1; }
code="$(cast code "${ARC_MAINNET_USDC_ADDRESS}" --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${code}" != "0x" ] || { echo "Arc Mainnet USDC bytecode is missing." >&2; exit 1; }
decimals="$(cast call "${ARC_MAINNET_USDC_ADDRESS}" 'decimals()(uint8)' --rpc-url "${ARC_MAINNET_RPC_URL}")"
[ "${decimals}" = "6" ] || { echo "Expected six-decimal ERC-20 USDC, got ${decimals}." >&2; exit 1; }

echo "Deployer: ${ARC_MAINNET_DEPLOYER_ADDRESS}"
echo "Native balance: $(cast balance "${ARC_MAINNET_DEPLOYER_ADDRESS}" --rpc-url "${ARC_MAINNET_RPC_URL}")"
echo "USDC balance (raw six-decimal units): $(cast call "${ARC_MAINNET_USDC_ADDRESS}" 'balanceOf(address)(uint256)' "${ARC_MAINNET_DEPLOYER_ADDRESS}" --rpc-url "${ARC_MAINNET_RPC_URL}")"
echo "Configured Mainnet chain: ${chain_id}"
echo "USDC: ${ARC_MAINNET_USDC_ADDRESS} (decimals ${decimals})"
echo "Explorer: ${ARC_MAINNET_EXPLORER_URL}"
echo "Arc Mainnet preflight passed for the supplied configuration."
