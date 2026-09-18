#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/foundry-env.sh"
: "${ARC_TESTNET_RPC_URL:?Set ARC_TESTNET_RPC_URL}"
: "${NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS:?Set NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS}"
: "${ARC_TESTNET_CREATOR_PRIVATE_KEY:?Set ARC_TESTNET_CREATOR_PRIVATE_KEY}"
: "${ARC_TESTNET_WORKER_PRIVATE_KEY:?Set ARC_TESTNET_WORKER_PRIVATE_KEY}"
(cd "${ROOT_DIR}/contracts" && forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig 'run(address,address)' "$NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS" 0x3600000000000000000000000000000000000000 --rpc-url "$ARC_TESTNET_RPC_URL" --private-key "$ARC_TESTNET_CREATOR_PRIVATE_KEY" --broadcast)
