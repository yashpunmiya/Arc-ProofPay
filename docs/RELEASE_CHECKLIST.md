# Release checklist

## Freeze

- [ ] Review and approve the frozen MVP commit.
- [ ] Confirm no product features or contract changes are planned after deployment.
- [ ] Confirm a dedicated deployer, creator, and worker wallet are used.

## Reproducible checks

```bash
./scripts/test-all.sh
```

- [ ] `forge fmt --check`
- [ ] Solidity build and unit/fuzz tests
- [ ] Local Anvil lifecycle
- [ ] Frontend lint, TypeScript, unit tests, production build
- [ ] Compiled/frontend ABI consistency
- [ ] Secret scan
- [ ] Testnet preflight and latest smoke evidence reviewed

## Contract safety

- [ ] ProofPay constructor points to the intended six-decimal USDC contract.
- [ ] All token transfers use `SafeERC20`.
- [ ] State transitions happen before external payout calls and payout functions use reentrancy protection.
- [ ] No owner, upgradeability, emergency withdrawal, or hidden fee exists.
- [ ] Creator authorization and one-shot terminal states are covered by tests.
- [ ] Arc USDC blocklist/freeze risk is accepted and operationally monitored.

## Mainnet gate

- [x] Official Arc Mainnet chain ID, RPC, explorer, and USDC address are published and entered in the Mainnet-only environment.
- [x] `./scripts/mainnet-preflight.sh` passes without broadcasting.
- [x] `ARC_MAINNET_PROOFPAY_ADDRESS` was empty before first deployment.
- [x] Deployment confirmation was set to `DEPLOY_PROOFPAY_WITH_REAL_USDC`.
- [x] `./scripts/mainnet-deploy.sh` output and `deployments/arc-mainnet.json` are archived.
- [x] Mainnet frontend configuration is reviewed separately from Testnet.
- [x] A one-raw-unit Mainnet lifecycle was run with explicit gas for `createTask`.
- [x] Smoke task status, payout, and explorer links are verified.

Mainnet V1 is deployed and verified. Preserve the recorded deployment and use the explicit Mainnet scripts for future operational checks.
