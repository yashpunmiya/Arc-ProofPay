# Build status

## Completed
- Next.js application, contract sources, deployment scripts, test/tooling and documentation.
- Arc Testnet configuration is centralized and deployment preflight validates chain, bytecode and ERC-20 decimals.
- Foundry compilation and test suite: 8 passed, including 256 fuzz runs and six-decimal token rejection coverage.
- Solidity formatting, ABI consistency, frontend lint, TypeScript, frontend unit tests, and production build checks are wired into the release scripts.
- Native Windows frontend checks pass; running the aggregate Bash script against the shared Windows `node_modules` from WSL needs a Linux-specific dependency install (Rollup optional binary).
- ProofPay deployed on Arc Testnet at `0x90a60E8704f48CEAD6e8CfDB7cf3Acb302303Dcd`.

## In progress
- A prior Testnet smoke attempt produced an `isBlocklisted`/`StackUnderflow` trace, but the issue is not currently reproducible: direct EOA `transferFrom` succeeds and a fresh deployment of the current ProofPay build completed a full 1-raw-unit escrow lifecycle.

## Blocked externally
- Testnet wallets are funded, network preflight passes, and the fresh-deployment lifecycle evidence is recorded in the release report.
- Arc Mainnet is publicly live at chain ID 5042 (`https://rpc.mainnet.arc.io`) with explorer `https://explorer.arc.io` and six-decimal USDC at `0x3600000000000000000000000000000000000000`. ProofPay is not deployed; preflight and deployment remain explicitly gated.

## Remaining
- Keep `scripts/testnet-usdc-repro.mjs` as the minimal regression check; complete manual visual QA and commit the frozen release tree.
