# ProofPay release-hardening security review

Date: 2026-09-18  
Mode: targeted mainnet-readiness / daily confidence gate

## Scope

`contracts/src/ProofPay.sol`, Foundry tests/scripts, frontend token amount/approval paths, deployment configuration, release scripts, dependency/configuration hygiene, and repository secret scan.

## Findings

No confirmed high-confidence fund-loss, authorization bypass, reentrancy, double-payment, double-refund, deadline, cancellation, rejection, or frontend unlimited-approval vulnerability was found in the reviewed code.

The contract now rejects a token whose `decimals()` is not exactly six at deployment. Payout/refund state is set before `SafeERC20` transfers under `ReentrancyGuard`; a failed transfer reverts the entire transaction. Terminal statuses prevent repeated settlement. Creator/worker checks and deadline checks are enforced on-chain.

## Operational gates

- Arc Mainnet is not currently documented as live by the official Arc docs; the preflight/deploy scripts fail closed without explicit Mainnet values.
- Arc Testnet preflight passes, but the funded smoke currently reverts in the Arc USDC contract-spender `isBlocklisted` precompile path during `transferFrom`. This is an external dependency and blocks claiming a successful live lifecycle.
- Arc USDC blocklisting can freeze transfers to/from affected addresses. This is a chain/token operational risk, not bypassable by ProofPay.

## Verification evidence

- `forge fmt --check`: passed.
- `forge build`: passed (Foundry emits informational timestamp/uint64 lint warnings).
- `forge test`: 8 passed, including 256 fuzz runs.
- ABI consistency check: passed.
- ESLint: passed.
- TypeScript: passed.
- Vitest: 2 passed.
- Production build: passed.
- Local Anvil lifecycle: passed.
- Secret scan: no obvious tracked secrets.

## Confidence calibration

- Confirmed high-confidence vulnerabilities: 0
- External release blockers: 2 (Mainnet not documented; Testnet smoke precompile revert)
- Informational operational risks: 1 (USDC blocklisting/freeze behavior)
- False positives filtered: test-only max approval, docs examples, development artifacts, and Foundry timestamp warnings.
