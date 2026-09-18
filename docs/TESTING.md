# Testing

Run `./scripts/test-all.sh` for shell validation, Foundry formatting/build/tests, ABI consistency, local lifecycle checks, web lint/typechecking/tests/build, and a lightweight secret scan.

- `./scripts/test-contracts.sh`: unit and fuzz tests.
- `./scripts/test-local-integration.sh`: lifecycle-focused local checks (Anvil required).
- `./scripts/test-web.sh`: ESLint, TypeScript, Vitest, production build.
- `./scripts/testnet-preflight.sh`: RPC chain, USDC code, and six-decimal checks.
- `./scripts/mainnet-preflight.sh`: gated, read-only Mainnet RPC/token/deployer/config/build checks.

Playwright is intentionally excluded; manual UI QA should cover 375px, 768px and desktop widths, wallet rejection, wrong network, empty state, and RPC failure. Testnet validates Arc behavior only once funded credentials are supplied.
