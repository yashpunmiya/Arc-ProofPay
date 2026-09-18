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
The frozen MVP has a tested Solidity escrow, local lifecycle, testnet deployment tooling, a reactive frontend, exact six-decimal USDC parsing/approvals, and gated Mainnet preparation scripts. See BUILD_STATUS and RELEASE_CHECKLIST for verified evidence and current release gates.

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

Mainnet is intentionally not deployed. Arc Mainnet is live, but deployment remains explicitly gated until the release checklist and Testnet escrow investigation are complete.
