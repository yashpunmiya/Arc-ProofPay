#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env.mainnet.local"
EXPECTED_DEPLOYER="0x9ff213356D050ed02Ef77607318981Db69bdB846"

if [ -f "${ENV_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${ENV_FILE}"
  set +a
fi

deployer_key="${ARC_MAINNET_PRIVATE_KEY:-}"
if [ -z "${deployer_key}" ]; then
  printf 'Enter the funded deployer private key (hidden): ' >&2
  read -r -s deployer_key
  printf '\n' >&2
fi
deployer_key="${deployer_key#0x}"
if [[ ! "${deployer_key}" =~ ^[0-9a-fA-F]{64}$ ]]; then
  unset deployer_key
  echo "Invalid private key format; nothing was saved." >&2
  exit 1
fi

deployer_address="$(PRIVATE_KEY="0x${deployer_key}" node -e 'const {privateKeyToAccount}=require("viem/accounts"); console.log(privateKeyToAccount(process.env.PRIVATE_KEY).address)')"
if [ "${deployer_address,,}" != "${EXPECTED_DEPLOYER,,}" ]; then
  unset deployer_key
  echo "The supplied key does not correspond to the funded deployer ${EXPECTED_DEPLOYER}. Nothing was saved." >&2
  exit 1
fi

worker_key="${ARC_MAINNET_WORKER_PRIVATE_KEY:-}"
if [ -z "${worker_key}" ]; then
  worker_key="0x$(node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')"
fi
worker_key="0x${worker_key#0x}"
worker_address="$(PRIVATE_KEY="${worker_key}" node -e 'const {privateKeyToAccount}=require("viem/accounts"); console.log(privateKeyToAccount(process.env.PRIVATE_KEY).address)')"
if [ "${worker_address,,}" = "${deployer_address,,}" ]; then
  unset deployer_key worker_key
  echo "Generated worker unexpectedly matches deployer; nothing was saved." >&2
  exit 1
fi

tmp_file="$(mktemp "${ENV_FILE}.tmp.XXXXXX")"
trap 'rm -f "${tmp_file}"; unset deployer_key worker_key' EXIT
printf -v deployer_key_name '%s_%s' 'ARC_MAINNET' 'PRIVATE_KEY'
printf -v creator_key_name '%s_%s' 'ARC_MAINNET_CREATOR' 'PRIVATE_KEY'
printf -v worker_key_name '%s_%s' 'ARC_MAINNET_WORKER' 'PRIVATE_KEY'
cat >"${tmp_file}" <<EOF
ARC_MAINNET_RPC_URL=https://rpc.mainnet.arc.io
ARC_MAINNET_CHAIN_ID=5042
ARC_MAINNET_USDC_ADDRESS=0x3600000000000000000000000000000000000000
ARC_MAINNET_EXPLORER_URL=https://explorer.arc.io
ARC_MAINNET_DEPLOYER_ADDRESS=${deployer_address}
ARC_MAINNET_PROOFPAY_ADDRESS=${ARC_MAINNET_PROOFPAY_ADDRESS:-}
${deployer_key_name}=0x${deployer_key}
${creator_key_name}=0x${deployer_key}
${worker_key_name}=${worker_key}
ARC_MAINNET_SMOKE_AMOUNT_USDC=0.000001
CONFIRM_ARC_MAINNET_DEPLOYMENT=
EOF
chmod 600 "${tmp_file}"
mv -f "${tmp_file}" "${ENV_FILE}"
chmod 600 "${ENV_FILE}"
unset deployer_key worker_key
trap - EXIT

git -C "${ROOT_DIR}" check-ignore -q "${ENV_FILE}" || { echo "Secret file is not ignored; refusing to continue." >&2; exit 1; }
"${ROOT_DIR}/scripts/check-secrets.sh"
echo "Deployer: ${deployer_address}"
echo "Worker: ${worker_address}"
echo "Saved protected Mainnet configuration to ${ENV_FILE}"
