#!/usr/bin/env bash
set -euo pipefail

if ! command -v forge >/dev/null 2>&1 && [ -x "${HOME}/.foundry/bin/forge" ]; then
  export PATH="${HOME}/.foundry/bin:${PATH}"
fi

command -v forge >/dev/null 2>&1 || { echo "Foundry (forge) is required." >&2; exit 1; }
