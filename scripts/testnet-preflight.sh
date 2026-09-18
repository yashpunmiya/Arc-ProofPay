#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/foundry-env.sh"
: "${ARC_TESTNET_RPC_URL:?Set ARC_TESTNET_RPC_URL}"
chain=$(cast chain-id --rpc-url "$ARC_TESTNET_RPC_URL")
[ "$chain" = "5042002" ] || { echo "Unexpected chain ID: $chain" >&2; exit 1; }
code=$(cast code 0x3600000000000000000000000000000000000000 --rpc-url "$ARC_TESTNET_RPC_URL")
[ "$code" != "0x" ] || { echo "Arc USDC ERC-20 bytecode missing" >&2; exit 1; }
decimals=$(cast call 0x3600000000000000000000000000000000000000 'decimals()(uint8)' --rpc-url "$ARC_TESTNET_RPC_URL")
[ "$decimals" = "6" ] || { echo "Expected 6-decimal ERC-20 USDC, got $decimals" >&2; exit 1; }
echo "Arc Testnet preflight passed."
