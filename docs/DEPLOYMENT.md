# Deployment

ProofPay is an immutable escrow contract. Mainnet deployment is a deliberate, manual operation and is never run by install, build, tests, CI, or the frontend.

## Local

Install Foundry and dependencies, then run:

```bash
cd contracts
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std --no-commit
cd ..
./scripts/test-local-integration.sh
```

The local lifecycle uses `MockUSDC`, which implements six decimals. It must never be deployed to Arc.

## Arc Testnet

Use a dedicated funded test wallet and load the variables from `.env.local` (never commit it):

```bash
set -a; . ./.env.local; set +a
./scripts/testnet-preflight.sh
```

The current Testnet contract is `0x90a60E8704f48CEAD6e8CfDB7cf3Acb302303Dcd`. Run the funded lifecycle only when you intentionally want to spend testnet USDC:

```bash
./scripts/testnet-smoke.sh
```

The Testnet deployment and smoke evidence are tracked in `docs/BUILD_STATUS.md`.

## Arc Mainnet

Arc Mainnet is live with chain ID `5042`, RPC `https://rpc.mainnet.arc.io`, explorer `https://explorer.arc.io`, and six-decimal USDC at `0x3600000000000000000000000000000000000000`. Verify these values against the live RPC before any deployment.

Read-only preflight (never broadcasts):

```bash
set -a; . ./.env.local; set +a
./scripts/mainnet-preflight.sh
```

After preflight passes, deploy manually with a dedicated deployer. The confirmation string is intentionally verbose:

```bash
CONFIRM_ARC_MAINNET_DEPLOYMENT=DEPLOY_PROOFPAY_WITH_REAL_USDC \
  ./scripts/mainnet-deploy.sh
```

The script refuses Testnet endpoints, wrong chain IDs, non-six-decimal USDC, existing deployment metadata, and mismatched deployer addresses. It writes public metadata to `deployments/arc-mainnet.json` and never prints a private key.

The verified Mainnet V1 contract is `0x1d81c9593536d814ae0976903b1df49CE8e8e401`; deployment and smoke transaction hashes are recorded in `deployments/arc-mainnet.json`.

The frontend uses `parseUnits(..., 6)` for bounty amounts, requests only the exact allowance required, and supplies centralized bounded gas limits for approvals and every ProofPay state-changing method. Run `pnpm check:mainnet-writes` to verify the same calldata/gas request shape and live Mainnet addresses without broadcasting.

After deployment, set `ARC_MAINNET_PROOFPAY_ADDRESS` and fund dedicated creator/worker wallets with the minimum real USDC required for the tiny smoke. Do not run the smoke automatically:

```bash
./scripts/mainnet-smoke.sh
```

The smoke amount defaults to `0.000001` USDC (one raw six-decimal unit) and can be changed with `ARC_MAINNET_SMOKE_AMOUNT_USDC` (maximum six decimal places). It verifies create, claim, proof submission, approval, completed status, payout, and zero remaining escrow. The verified lifecycle used explicit gas for `createTask` because Arc USDC blocklist simulation can return a false-negative precompile error; the real receipt succeeded.

Official references: [Arc documentation index](https://docs.arc.io/llms.txt), [network deployment model](https://docs.arc.io/arc/concepts/deployment-model), and [Arc USDC transfer reference](https://docs.arc.io/integrate/infrastructure/indexing-events).
