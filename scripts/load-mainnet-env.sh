#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MAINNET_ENV_FILE="${MAINNET_ENV_FILE:-${ROOT_DIR}/.env.mainnet.local}"
if [ -f "${MAINNET_ENV_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${MAINNET_ENV_FILE}"
  set +a
fi
