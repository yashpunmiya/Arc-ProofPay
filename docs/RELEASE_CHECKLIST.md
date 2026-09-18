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

- [ ] Official Arc Mainnet chain ID, RPC, explorer, and USDC address are published and entered in the Mainnet-only environment.
- [ ] `./scripts/mainnet-preflight.sh` passes without broadcasting.
- [ ] `ARC_MAINNET_PROOFPAY_ADDRESS` is empty before first deployment.
- [ ] Deployment confirmation is set manually to `DEPLOY_PROOFPAY_WITH_REAL_USDC`.
- [ ] `./scripts/mainnet-deploy.sh` output and `deployments/arc-mainnet.json` are archived.
- [ ] Mainnet frontend configuration is reviewed separately from Testnet.
- [ ] `./scripts/mainnet-smoke.sh` is run manually with the smallest practical amount.
- [ ] Smoke task status, payout, and explorer links are verified.

Mainnet deployment remains **NOT READY** until live RPC checks pass, the repository is frozen, and the Testnet escrow lifecycle is explained and successful with the current contract build.
