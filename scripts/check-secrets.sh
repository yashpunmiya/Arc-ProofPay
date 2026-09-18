#!/usr/bin/env bash
set -euo pipefail

private_key_pattern='ARC_(TESTNET|MAINNET)_(PRIVATE_KEY|CREATOR_PRIVATE_KEY|WORKER_PRIVATE_KEY)[[:space:]]*=[[:space:]]*[^$[:space:]]+'
mnemonic_pattern='mnemonic[[:space:]]*=[[:space:]]*[^$[:space:]]+'
if git grep -nEi "${private_key_pattern}" -- ':!.env.example' || git grep -nEi "${mnemonic_pattern}" -- ':!.env.example'; then
  echo "Potential secret found in tracked files." >&2
  exit 1
fi
echo "No obvious tracked secrets found."
