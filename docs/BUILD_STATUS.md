# Build status

## Completed
- Next.js application, immutable ProofPay escrow, deployment scripts, test tooling, and release documentation.
- Arc Testnet and Arc Mainnet configuration are separated and preflight validates chain, bytecode, and six-decimal USDC.
- Foundry compilation/tests: 8 passed, including fuzz and six-decimal token rejection coverage.
- Solidity formatting, ABI consistency, frontend lint/typecheck/unit tests, production build, and secret scan are wired into the release suite.
- ProofPay is deployed and verified on Arc Mainnet at `0x1d81c9593536d814ae0976903b1df49CE8e8e401`.
- A one-raw-unit Mainnet lifecycle completed create → claim → submit → approve → payout; evidence is recorded in `deployments/arc-mainnet.json`.
- Frontend writes use six-decimal parsing, exact approvals, and centralized bounded gas limits to avoid Arc simulation false-negatives.

## Arc note
Arc USDC can expose an `isBlocklisted`/`OpcodeNotFound` false-negative during gas estimation. The same transfer path succeeds with the bounded explicit gas used by the verified lifecycle. `pnpm check:mainnet-writes` is read-only and checks the current request shape.

## Remaining
- Host the frontend with user-supplied provider credentials and record the real public URL. No hosting URL is fabricated in project documentation.
