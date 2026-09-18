#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/foundry-env.sh"

for function_name in taskCount getTask createTask claimTask releaseClaim submitProof approveAndPay rejectAndRefund cancelTask refundExpiredTask usdc; do
  node -e 'const fs=require("fs"); const abi=JSON.parse(fs.readFileSync(process.argv[1],"utf8")).abi; process.exit(abi.some((x)=>x.type==="function"&&x.name===process.argv[2])?0:1)' "${ROOT_DIR}/contracts/out/ProofPay.sol/ProofPay.json" "${function_name}" || {
    echo "Missing ${function_name} in compiled ProofPay ABI." >&2
    exit 1
  }
done

grep -q 'name:"usdc"' "${ROOT_DIR}/lib/proofpay.ts" || {
  echo "Missing usdc() ABI in frontend ABI definitions." >&2
  exit 1
}
echo "ProofPay ABI consistency passed."
