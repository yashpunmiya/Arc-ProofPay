#!/usr/bin/env bash
set -euo pipefail
for script in scripts/*.sh; do bash -n "${script}"; done
./scripts/test-contracts.sh
./scripts/test-local-integration.sh
./scripts/test-web.sh
./scripts/check-secrets.sh
