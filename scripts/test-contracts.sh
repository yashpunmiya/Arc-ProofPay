#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/foundry-env.sh"
(cd "${ROOT_DIR}/contracts" && forge fmt --check && forge build && forge test)
"${ROOT_DIR}/scripts/check-abi.sh"
