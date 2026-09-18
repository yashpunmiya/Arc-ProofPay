#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/foundry-env.sh"
command -v anvil >/dev/null || { echo "Anvil is required for local integration." >&2; exit 1; }
anvil --silent >/tmp/proofpay-anvil.log 2>&1 &
ANVIL_PID=$!
trap 'kill "$ANVIL_PID" 2>/dev/null || true' EXIT
sleep 2
(cd "${ROOT_DIR}/contracts" && forge script script/LocalLifecycle.s.sol:LocalLifecycle --rpc-url http://127.0.0.1:8545 --broadcast)
