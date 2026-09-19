# Arc Microgrant Submission

## Name
ProofPay

## Tagline
Outcome-based USDC bounties on Arc.

## Short description
ProofPay lets a creator escrow USDC for a small, concrete outcome. A worker claims the task, submits a proof URL, and the creator accepts to settle payment automatically.

## Problem and solution
Small internet-native jobs are too small for conventional invoicing. ProofPay makes a simple escrow → delivery → settlement path visible and auditable.

## Why Arc
Arc's USDC-native fee model and EVM compatibility fit small programmable payments.

## What is working
The frozen MVP has a tested Solidity escrow, local lifecycle, testnet deployment tooling, a reactive frontend, exact six-decimal USDC parsing/approvals, and a verified Arc Mainnet deployment. See `deployments/arc-mainnet.json`, BUILD_STATUS, and RELEASE_CHECKLIST for evidence.

## Tech stack
Next.js, wagmi, viem, Solidity, Foundry, OpenZeppelin.

## Contract address
Arc Testnet: `0x90a60E8704f48CEAD6e8CfDB7cf3Acb302303Dcd`

## Demo URL
NOT DEPLOYED YET

## Repository
Repository URL not configured.

## Mainnet evidence checklist
- [ ] Contract and explorer URL
- [ ] Create, claim, submit, payout transactions
- [ ] Live frontend and public repository

Mainnet ProofPay V1: `0x1d81c9593536d814ae0976903b1df49CE8e8e401`.

The one-raw-unit Mainnet lifecycle completed successfully using explicit gas for `createTask`; explorer transaction links are recorded in `deployments/arc-mainnet.json`.
