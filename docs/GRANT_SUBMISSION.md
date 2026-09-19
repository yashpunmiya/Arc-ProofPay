# Arc Microgrant Submission

## Name
ProofPay

## Tagline
Outcome-based USDC bounties on Arc.

## What it is
ProofPay is a small, transparent escrow for internet-native work. A creator deposits six-decimal USDC, a worker claims the task and submits a proof URL, and the creator approves payment or rejects and refunds the escrow. Open and claimed tasks can be refunded after their deadline.

## Why Arc
Arc’s EVM compatibility and USDC-native fee model make tiny programmable payments practical. ProofPay uses the Arc ERC-20 USDC interface for application escrow and never sends bounty value as native `msg.value`.

## Verified Mainnet deployment
- Network: Arc Mainnet, chain ID `5042`
- ProofPay V1: `0x1d81c9593536d814ae0976903b1df49CE8e8e401`
- USDC: `0x3600000000000000000000000000000000000000` (decimals `6`)
- Explorer: [Arc Explorer](https://explorer.arc.io/address/0x1d81c9593536d814ae0976903b1df49CE8e8e401)
- Deployment transaction: [0x0ca7e9…](https://explorer.arc.io/tx/0x0ca7e926cb2b57051e2aaf802534f054420130128a112ec29dbfcaa58dc00e8d)

The recorded one-raw-unit lifecycle completed create → claim → submit → approve → payout. Full hashes and receipts are in [`deployments/arc-mainnet.json`](../deployments/arc-mainnet.json).

## Product and technical proof
Next.js, wagmi, viem, Solidity, Foundry, and OpenZeppelin. The repository includes local Anvil integration, Foundry unit/fuzz tests, testnet smoke tooling, a read-only Mainnet preflight, exact-amount approvals, bounded transaction gas limits, and a clean secret scan. The frontend is not represented as publicly hosted until a real hosting URL exists.

## Trust model
Creators decide whether submitted work is accepted. There is no dispute arbitration or upgrade authority in the immutable escrow contract. Users should review the source and transaction details before signing. This project is not professionally audited.

## Repository
Repository URL is not configured in this workspace.
