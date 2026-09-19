# ProofPay

Outcome-based USDC bounties on Arc.

## What it does

A creator posts a task and escrows ERC-20 USDC. A worker claims it, submits a proof URL, and the creator either approves (paying the worker) or rejects (refunding escrow). Open or claimed tasks can be refunded after their submission deadline.

## Lifecycle

`CREATE → CLAIM → SUBMIT → APPROVE → PAY`

Creators may cancel only open tasks; submitted work may be rejected and refunded; expired open/claimed work can be refunded. The creator controls acceptance—there is no dispute arbitration.

## Why Arc

Arc is EVM-compatible and uses USDC for gas. ProofPay uses Arc's 6-decimal ERC-20 USDC interface for application escrow, never `msg.value`.

## Architecture

```text
Browser → Next.js + wagmi/viem → ProofPay.sol → Arc ERC-20 USDC
```

## Develop

```bash
pnpm install
pnpm dev
./scripts/test-web.sh
./scripts/test-contracts.sh
./scripts/test-all.sh
```

Install Foundry and contract dependencies first: `cd contracts && forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std --no-commit`.

## Arc Testnet

Copy `.env.example` to `.env.local`, configure a current Testnet RPC and deployed address, then run `./scripts/testnet-preflight.sh`. A funded creator wallet is required for deployment and lifecycle smoke testing. See [deployment documentation](docs/DEPLOYMENT.md).

## Arc Mainnet

ProofPay V1 is deployed and smoke-tested on Arc Mainnet (chain ID `5042`, RPC `https://rpc.mainnet.arc.io`, explorer `https://explorer.arc.io`). The production contract is `0x1d81c9593536d814ae0976903b1df49ce8e8e401` and uses six-decimal USDC at `0x3600000000000000000000000000000000000000`.

Deployment and one-raw-unit lifecycle evidence are recorded in [`deployments/arc-mainnet.json`](deployments/arc-mainnet.json). Mainnet scripts remain explicitly gated and never run automatically.

```bash
./scripts/mainnet-preflight.sh
CONFIRM_ARC_MAINNET_DEPLOYMENT=DEPLOY_PROOFPAY_WITH_REAL_USDC ./scripts/mainnet-deploy.sh
./scripts/mainnet-smoke.sh
```

See [deployment documentation](docs/DEPLOYMENT.md) and [release checklist](docs/RELEASE_CHECKLIST.md) before using real USDC.

## Security

Read [SECURITY.md](SECURITY.md). This project is not professionally audited.

## License

MIT.
