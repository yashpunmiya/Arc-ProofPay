# ProofPay — Complete MVP Build Specification

You are the lead engineer responsible for building, testing, documenting, and preparing a complete production-quality MVP called **ProofPay**.

Do not only scaffold the project. Continue working until the complete MVP is implemented and all automated checks that can run in the current environment pass.

Do not stop after each phase to ask me what to do next.

Use sensible engineering judgment where minor details are unspecified.

Do not add unnecessary features.

Do not deploy to Arc Mainnet yet.

The project must first be fully working locally and, when funded test wallets are available, on Arc Testnet.

---

# 1. PRODUCT

ProofPay is a minimal outcome-based bounty application built for Arc.

The product thesis:

**Post a small task, escrow USDC, receive completed work, and release the bounty when the result is accepted.**

Example bounties:

- Fix a mobile CSS bug — 5 USDC
- Translate a README — 3 USDC
- Review a pull request — 8 USDC
- Design a small icon — 4 USDC
- Write a short technical summary — 2 USDC

The application should demonstrate a very clear lifecycle:

CREATE → CLAIM → SUBMIT → APPROVE → PAY

The application must use real smart-contract interactions.

Do not mock blockchain transactions in the finished application.

---

# 2. PRODUCT PRINCIPLES

This is a small grant-quality MVP.

Optimize for:

1. Reliability
2. Clear smart-contract behavior
3. Excellent basic UX
4. Clean source code
5. Easy review
6. Easy demo
7. Strong documentation
8. Small scope

Do NOT build:

- chat
- messaging
- DAO governance
- reputation systems
- arbitration systems
- AI evaluation
- AI agents
- notifications
- email
- user accounts
- usernames
- profile pages
- social feeds
- admin dashboards
- complicated analytics
- a backend database
- a custom indexer
- tokenomics
- a ProofPay token
- NFT functionality
- upgradeable smart contracts

Do not turn this into a generic freelance marketplace.

ProofPay should remain one focused payment primitive.

---

# 3. IMPORTANT ARC NETWORK MODEL

ProofPay targets Arc.

Arc is EVM-compatible.

USDC is also Arc's native gas asset.

Arc exposes the underlying USDC balance through two interfaces:

1. Native interface:
   - 18-decimal EVM-native representation
   - used for gas
   - native transfers
   - msg.value

2. ERC-20 interface:
   - 6 decimals
   - used for application-level USDC transfers
   - transfer
   - transferFrom
   - approve
   - allowance

For ProofPay escrow, use the **ERC-20 USDC interface**.

Do not use msg.value for bounty escrow.

All bounty values in contracts and application logic must be stored as the raw 6-decimal ERC-20 USDC amount.

Examples:

1 USDC = 1_000_000

5 USDC = 5_000_000

Frontend code must use:

parseUnits(value, 6)

and:

formatUnits(value, 6)

for bounty amounts.

Never accidentally use parseEther for bounty escrow.

Never add the native USDC balance and ERC-20 balance together. They represent the same underlying asset.

---

# 4. VERIFY ARC CONFIGURATION BEFORE NETWORK OPERATIONS

Before implementing any network-specific deployment logic, consult the CURRENT official Arc documentation.

Relevant official material includes:

- Arc documentation
- Arc "USDC for Every Action" developer guidance
- Arc EVM compatibility guidance
- Arc network configuration documentation
- Arc transaction lifecycle documentation
- Arc contract-address documentation

Expected values at the time this specification was written include:

Arc Testnet:
- chain ID expected: 5042002
- USDC ERC-20 predeploy expected:
  0x3600000000000000000000000000000000000000

Arc Mainnet:
- chain ID expected: 5042
- USDC ERC-20 predeploy expected:
  0x3600000000000000000000000000000000000000

Do NOT blindly trust constants from this prompt.

Before a deployment script broadcasts anything:

1. call eth_chainId against the configured RPC
2. compare it against the expected chain
3. check bytecode exists at the configured USDC address
4. query decimals() from the USDC interface
5. require decimals == 6
6. abort on any mismatch

Network configuration must live in configuration modules/environment files rather than being scattered throughout the repository.

---

# 5. STACK

Use a straightforward stack.

## Frontend

- Next.js
- TypeScript
- App Router
- Tailwind CSS
- shadcn/ui where useful
- wagmi
- viem
- TanStack Query through wagmi where appropriate
- Zod for form validation if useful

Use the current stable compatible versions.

Do not upgrade packages unnecessarily once the project is working.

## Smart contracts

- Solidity
- Foundry
- OpenZeppelin contracts

Use:

- IERC20
- SafeERC20
- ReentrancyGuard

Do not use Hardhat in addition to Foundry.

One Solidity toolchain is enough.

## Testing

Smart contracts:
- Foundry tests
- Foundry fuzz tests where valuable
- local Anvil integration scenario

Frontend:
- TypeScript typecheck
- ESLint
- production build
- Vitest
- React Testing Library for important components/helpers where useful

Integration:
- shell scripts
- Foundry scripts
- cast
- optional small TypeScript/viem CLI scripts when they simplify assertions

DO NOT install or use Playwright.

DO NOT install Cypress.

DO NOT build browser automation.

Everything should be verifiable from CLI scripts.

---

# 6. REPOSITORY STRUCTURE

Prefer a structure approximately like:

/
  app/
  components/
  hooks/
  lib/
  public/
  contracts/
    src/
    test/
    script/
    lib/
    foundry.toml
  scripts/
  deployments/
  docs/
  .github/
    workflows/
  .env.example
  package.json
  README.md
  SECURITY.md
  LICENSE

The Next.js application may live at the repository root.

The Foundry project should live under /contracts.

Keep the repository easy for a reviewer to understand.

Avoid unnecessary monorepo tooling.

---

# 7. SMART CONTRACT

Create:

contracts/src/ProofPay.sol

The contract must be:

- non-upgradeable
- permissionless
- without admin withdrawal powers
- without owner-controlled escrow seizure
- immutable with respect to the configured USDC token
- straightforward to audit

Constructor:

constructor(address usdc)

Store:

IERC20 public immutable usdc;

Validate that the address is nonzero.

---

# 8. TASK MODEL

Use monotonically increasing task IDs starting at 1.

Use an enum similar to:

enum Status {
    OPEN,
    CLAIMED,
    SUBMITTED,
    COMPLETED,
    CANCELLED,
    REFUNDED,
    REJECTED
}

Use a Task struct containing approximately:

uint256 id;
address creator;
address worker;
uint256 amount;
uint64 deadline;
uint64 createdAt;
uint64 claimedAt;
uint64 submittedAt;
Status status;
string title;
string description;
string proofURI;

Use appropriate integer sizing only where it genuinely improves clarity/storage.

Do not over-optimize storage at the expense of maintainability.

---

# 9. STRING LIMITS

Because task metadata is stored onchain for this MVP, enforce reasonable limits.

Suggested constants:

MAX_TITLE_BYTES = 120
MAX_DESCRIPTION_BYTES = 1500
MAX_PROOF_URI_BYTES = 500

Validate byte lengths.

Do not allow blank titles.

Do not allow blank proof URLs when submitting.

The frontend must enforce the same limits before sending transactions.

---

# 10. DEADLINE RULES

The deadline represents the deadline for the worker to submit work.

When creating:

- amount must be greater than zero
- deadline must be in the future
- require a sensible minimum lead time
- do not permit absurdly distant deadlines

For example:

MIN_DEADLINE_DELAY = 10 minutes
MAX_DEADLINE_DELAY = 90 days

Use constants and test boundaries.

A worker cannot claim an expired bounty.

A worker cannot submit after the submission deadline.

If work was submitted before the deadline, approval/rejection may occur after the deadline.

---

# 11. CONTRACT FUNCTIONS

Implement approximately these functions.

## createTask

createTask(
    string calldata title,
    string calldata description,
    uint256 amount,
    uint64 deadline
)

Behavior:

1. validate fields
2. assign next task ID
3. transfer exactly `amount` of USDC from creator into ProofPay
4. create task in OPEN state
5. emit TaskCreated
6. return task ID if useful

Use SafeERC20.safeTransferFrom.

The frontend will handle approval before invoking this function.

---

## claimTask

claimTask(uint256 taskId)

Rules:

- task exists
- status == OPEN
- deadline has not passed
- msg.sender != creator
- worker becomes msg.sender
- status becomes CLAIMED
- claimedAt recorded

Emit TaskClaimed.

---

## releaseClaim

Optional but recommended because it is simple and improves UX.

releaseClaim(uint256 taskId)

Rules:

- caller must be current worker
- status == CLAIMED
- task not submitted
- deadline has not passed

Behavior:

- worker set back to address(0)
- claimedAt reset
- status becomes OPEN

Emit TaskClaimReleased.

This lets a worker voluntarily give up a task.

---

## submitProof

submitProof(
    uint256 taskId,
    string calldata proofURI
)

Rules:

- task exists
- status == CLAIMED
- caller == worker
- deadline has not passed
- proofURI is non-empty and within max length

Behavior:

- store proofURI
- set submittedAt
- status = SUBMITTED

Emit ProofSubmitted.

---

## approveAndPay

approveAndPay(uint256 taskId)

Rules:

- task exists
- caller == creator
- status == SUBMITTED
- worker is nonzero

Behavior:

1. update state before external token transfer
2. status = COMPLETED
3. transfer exactly `amount` USDC to worker
4. emit TaskCompleted

Use nonReentrant.

Use SafeERC20.

---

## rejectAndRefund

Because this MVP has no arbitration layer, implement an explicit creator-controlled rejection path.

rejectAndRefund(
    uint256 taskId,
    string calldata reason
)

Rules:

- caller == creator
- status == SUBMITTED
- reason must be short and non-empty

Behavior:

- status = REJECTED
- return escrow to creator
- emit TaskRejected

Document very clearly:

**ProofPay MVP uses creator-controlled acceptance and has no dispute arbitration.**

Do not pretend this model is trustless arbitration.

---

## cancelTask

cancelTask(uint256 taskId)

Rules:

- caller == creator
- status == OPEN

Behavior:

- status = CANCELLED
- return escrow to creator
- emit TaskCancelled

Creator must NOT be able to cancel a currently CLAIMED task before deadline.

---

## refundExpiredTask

refundExpiredTask(uint256 taskId)

Rules:

- deadline has passed
- status is OPEN or CLAIMED

Behavior:

- status = REFUNDED
- escrow returns to creator
- emit TaskRefunded

Anyone may trigger this function if that makes implementation simpler, because funds always return to the creator.

A SUBMITTED task must not automatically refund merely because the deadline passed, since the work was submitted before the deadline.

---

# 12. READ METHODS

Provide easy read methods.

At minimum:

taskCount()

getTask(uint256 taskId)

tasks(uint256 id) may be public if practical.

Avoid complicated pagination contracts unless necessary.

For the frontend, fetching the newest N task IDs is sufficient.

The frontend may display the most recent 50 tasks.

---

# 13. EVENTS

Implement clear indexed events.

For example:

TaskCreated
TaskClaimed
TaskClaimReleased
ProofSubmitted
TaskCompleted
TaskRejected
TaskCancelled
TaskRefunded

Index:

- taskId
- creator where appropriate
- worker where appropriate

Do not emit large duplicated strings unless they meaningfully help.

---

# 14. CUSTOM ERRORS

Prefer custom Solidity errors over long revert strings.

Examples:

TaskNotFound
InvalidAmount
InvalidDeadline
TitleRequired
TitleTooLong
DescriptionTooLong
ProofRequired
ProofTooLong
Unauthorized
InvalidStatus
DeadlinePassed
DeadlineNotPassed
CreatorCannotClaim
InvalidToken

Keep them understandable.

---

# 15. CONTRACT SECURITY REQUIREMENTS

Apply checks-effects-interactions.

Use ReentrancyGuard around escrow-moving functions where appropriate.

Use SafeERC20 for all ERC-20 transfers.

Never use unlimited allowances from the contract.

The contract itself should never need to approve another contract.

Do not create:

- owner withdrawal
- emergency arbitrary withdrawal
- delegatecall
- upgradeability
- selfdestruct
- proxy patterns
- arbitrary external calls

The total USDC held by the contract should correspond to unresolved escrowed tasks.

Document the trust assumptions.

---

# 16. CONTRACT TEST SUITE

Create comprehensive Foundry tests.

Do not merely test the happy path.

At minimum test:

## Creation

- task created correctly
- amount escrowed
- exact task counter increment
- event emitted
- zero amount rejected
- expired deadline rejected
- too-short deadline rejected
- too-far deadline rejected
- empty title rejected
- title too long rejected
- description too long rejected
- transfer without allowance fails
- insufficient USDC fails

## Claiming

- another wallet can claim
- creator cannot claim their own task
- second worker cannot steal claim
- expired bounty cannot be claimed
- non-open bounty cannot be claimed

## Release claim

- worker can release claim
- random wallet cannot
- submitted task cannot be released

## Submission

- assigned worker can submit
- creator cannot submit as worker
- unrelated wallet cannot submit
- empty proof rejected
- overlong proof rejected
- submission after deadline rejected
- second submission rejected unless explicitly supported

## Approval

- creator can approve submitted work
- worker receives exact escrow
- contract balance decreases correctly
- unrelated wallet cannot approve
- worker cannot approve
- double approval impossible
- unsubmitted task cannot be approved

## Rejection

- creator can reject submitted work
- escrow returns to creator
- worker is not paid
- unrelated wallet cannot reject
- rejection cannot occur twice
- completed task cannot be rejected

## Cancellation

- creator can cancel OPEN task
- escrow returned
- non-creator cannot cancel
- CLAIMED task cannot be cancelled
- submitted task cannot be cancelled

## Expiry

- expired OPEN task refunded
- expired CLAIMED task refunded
- nonexpired task cannot be refunded
- SUBMITTED task is not refundable using expiry
- funds returned exactly once

## Accounting

Add tests that verify:

contractUSDCBalance ==
sum of escrow for unresolved active tasks

for representative multi-task scenarios.

## Fuzzing

Use Foundry fuzz tests for:

- valid bounty amounts
- valid deadlines
- amount accounting
- state-transition restrictions where useful

Do not write meaningless fuzz tests only for coverage numbers.

---

# 17. LOCAL MOCK TOKEN

Create:

contracts/src/mocks/MockUSDC.sol

This is LOCAL TESTING ONLY.

Requirements:

- OpenZeppelin ERC20
- 6 decimals
- mint function usable in tests/local integration

Never deploy MockUSDC to Arc Testnet/Mainnet.

Never allow the production frontend to point to MockUSDC.

---

# 18. LOCAL FULL-LIFECYCLE INTEGRATION

Create a scripted local scenario using Anvil.

The scenario must automatically:

1. start Anvil or expect a local Anvil RPC
2. deploy MockUSDC
3. deploy ProofPay
4. mint test USDC to creator
5. mint enough gas/native currency as provided by Anvil
6. creator approves exact bounty amount
7. creator creates bounty
8. verify ProofPay token balance
9. worker claims bounty
10. worker submits proof
11. creator approves
12. verify worker USDC increased by exact bounty
13. verify task == COMPLETED
14. verify escrow was released
15. exit nonzero if any assertion fails

Also test at least one cancellation/refund lifecycle in an automated scenario.

No browser should be required.

---

# 19. FRONTEND PRODUCT

Create a polished but understated application.

Product name:

ProofPay

Primary tagline:

**Work agreed. Outcome delivered. Payment settled.**

Secondary copy may mention:

**Outcome-based USDC bounties on Arc.**

Do not fill the application with marketing copy.

The actual tasks should remain the focus.

---

# 20. VISUAL DIRECTION

The design should look like a small legitimate fintech/productivity product built by humans.

Avoid the stereotypical AI-generated landing-page aesthetic.

Specifically avoid:

- giant gradients
- purple/blue gradient backgrounds
- glowing blobs
- excessive glassmorphism
- excessive shadows
- giant hero text
- random illustrations
- fake logos
- fake customer testimonials
- fake enterprise badges
- unnecessary animations
- excessive rounded cards
- emoji-heavy interfaces
- multiple competing accent colors
- "revolutionary"
- "AI-powered"
- "next-generation"
- "future of work"
- blockchain buzzword spam

Use:

- light neutral background
- dark readable text
- one restrained accent
- subtle borders
- restrained border radius
- generous but not excessive spacing
- clear hierarchy
- professional typography
- excellent mobile layout

A visual reference should be:

modern payments dashboard + simple issue tracker

rather than:

crypto casino + hackathon landing page.

---

# 21. ACCESSIBILITY

Implement:

- semantic HTML
- labels for all form controls
- keyboard accessible actions
- visible focus states
- adequate contrast
- disabled states
- aria labels where necessary
- meaningful loading states
- no important information communicated only through color

---

# 22. HEADER

Header should contain:

Left:
- ProofPay wordmark/text

Center or simple nav:
- Bounties
- My work

Right:
- network indicator
- connected wallet control

Keep it compact.

---

# 23. HOMEPAGE

Homepage should have a restrained introductory section.

Example:

ProofPay

Work agreed.
Outcome delivered.
Payment settled.

Create small outcome-based jobs and settle them in USDC on Arc.

[Create bounty] [Browse bounties]

Below it, show actual application content quickly.

Do not force users through a huge marketing page.

---

# 24. BOUNTY LIST

Display recent bounties.

Each card/row should show:

- title
- short description
- bounty amount
- USDC
- status
- deadline
- shortened creator address
- worker if claimed
- View button/link

Provide simple filters:

- Open
- Active
- Completed
- All

When a wallet is connected also support:

- Created by me
- Claimed by me

Filtering can be client-side for the current fetched task set.

No backend is needed.

---

# 25. BOUNTY DETAIL PAGE

Route:

/bounty/[id]

Show:

- title
- full description
- bounty amount
- creator
- worker
- status
- creation time
- deadline
- proof URL if submitted
- transaction/action controls
- explorer links where relevant

Show a simple lifecycle visualization:

Created
Claimed
Submitted
Completed

Do not make this visually noisy.

Only show actions valid for the connected wallet and current state.

Examples:

OPEN + unrelated wallet:
[Claim bounty]

OPEN + creator:
[Cancel bounty]

CLAIMED + worker:
[Submit work]
[Release claim]

SUBMITTED + creator:
[Approve & pay]
[Reject & refund]

COMPLETED:
Paid to worker

---

# 26. CREATE BOUNTY PAGE

Route:

/create

Fields:

Title
Description
Bounty amount in USDC
Submission deadline

Display validation before blockchain interaction.

Show:

"You are escrowing X USDC."

Because ERC-20 USDC is used, creation should gracefully handle allowance.

Flow:

1. read current allowance
2. if allowance < bounty:
   show "Approve X USDC"
3. approve EXACT amount needed
4. wait for approval receipt
5. enable "Create bounty"
6. send createTask
7. wait for confirmed receipt
8. navigate to created bounty

Do NOT request unlimited approval.

Do NOT report success before transaction receipt status == success.

---

# 27. TRANSACTION UX

Every write action needs states:

idle
wallet confirmation
submitted
confirming
confirmed
failed

Use concise human copy.

Examples:

Waiting for wallet…
Transaction submitted…
Confirming on Arc…
Bounty created.
Payment released.

On errors, extract a useful error message where possible.

Do not dump raw JSON-RPC errors on normal users.

Allow users to inspect transaction hash/explorer link.

Never fabricate a transaction hash.

---

# 28. WALLET CONNECTION

Use wagmi.

At minimum support injected EVM wallets.

WalletConnect may be supported only if it can be added cleanly and an optional environment variable controls its project ID.

Do not require a paid third-party wallet service for the basic MVP.

Display:

0x1234…abcd

when connected.

Handle:

- disconnected wallet
- unsupported network
- network switching
- rejected signatures
- failed transactions

---

# 29. NETWORK MODE

Implement environment-controlled network selection.

For example:

NEXT_PUBLIC_ARC_ENV=testnet

Allowed values:

testnet
mainnet

Default development mode:

testnet

Do not silently fall back to mainnet.

Mainnet should require explicit configuration.

Centralize:

chain
RPC
explorer
USDC address
ProofPay address

inside one configuration module.

---

# 30. CONTRACT ADDRESS CONFIGURATION

Use deployment files.

For example:

deployments/arc-testnet.json
deployments/arc-mainnet.json

Each should contain relevant information such as:

{
  "chainId": ...,
  "network": "...",
  "proofPay": "...",
  "usdc": "...",
  "deployer": "...",
  "deploymentTx": "...",
  "deployedAt": "..."
}

Do not commit secrets.

The frontend should obtain the active ProofPay address from configuration/environment in one deterministic way.

Fail visibly if no contract is configured.

Do not substitute a fake address.

---

# 31. DATA LOADING

Avoid a backend/database.

Use direct contract reads.

Read:

taskCount

then fetch the latest tasks.

Cap homepage browsing to a sensible number such as the newest 50 tasks.

Use multicall/readContracts where appropriate.

Handle zero tasks correctly.

Handle RPC failure correctly.

Provide:

- loading skeleton
- empty state
- retry state

Do not show fake sample tasks in production mode.

Sample fixtures are fine for unit tests only.

---

# 32. FRONTEND CODE QUALITY

Separate:

- chain configuration
- ABI
- formatting
- contract reads
- contract writes
- presentation components

Generate or copy ABI deterministically from Foundry artifacts.

Create a script to sync the ABI after contract compilation.

Example:

scripts/sync-abi.sh

Do not manually maintain two ABIs that can drift.

---

# 33. FRONTEND TESTS

Without Playwright, write focused tests for important non-wallet behavior.

At minimum test:

- USDC formatter
- USDC amount parser/validation
- address shortening
- deadline formatting
- status labels
- form validation
- network config selection
- valid action availability from status/actor
- create form important states where practical

Prefer extracting state logic into pure functions so it can be tested without mocking an entire wallet stack.

Example helper:

getAvailableActions(task, connectedAddress, now)

Test its state matrix thoroughly.

---

# 34. COMMAND-LINE TESTING POLICY

All project verification must be executable via shell scripts.

Create scripts such as:

scripts/setup.sh
scripts/check-env.sh
scripts/test-contracts.sh
scripts/test-web.sh
scripts/test-local-integration.sh
scripts/test-all.sh
scripts/sync-abi.sh
scripts/arc-testnet-preflight.sh
scripts/arc-testnet-deploy.sh
scripts/arc-testnet-smoke.sh
scripts/mainnet-preflight.sh
scripts/mainnet-deploy.sh

Names may vary slightly, but capabilities must exist.

Scripts must:

- use `set -euo pipefail`
- fail on errors
- print readable section headings
- not expose private keys
- produce clear exit codes
- be rerunnable where practical

---

# 35. TEST-ALL SCRIPT

scripts/test-all.sh should run all deterministic local verification.

Expected sequence:

1. environment/tool checks
2. Solidity formatting check
3. Solidity compile
4. Solidity unit/fuzz tests
5. frontend lint
6. frontend typecheck
7. frontend unit tests
8. frontend production build
9. ABI consistency check
10. local Anvil integration lifecycle

A single command should give confidence:

./scripts/test-all.sh

This should become the canonical local verification command.

---

# 36. TEST AS YOU BUILD

Do not implement everything and test only at the end.

Work phase-by-phase.

After each meaningful phase:

1. run relevant tests
2. fix failures immediately
3. continue only after the current phase is green

Examples:

After smart contract:
./scripts/test-contracts.sh

After frontend:
./scripts/test-web.sh

After integration:
./scripts/test-local-integration.sh

Before declaring completion:
./scripts/test-all.sh

When a script fails:

- diagnose it
- fix the underlying issue
- rerun the relevant test

Do not silence tests merely to obtain green output.

---

# 37. NO PLAYWRIGHT

Do not install Playwright.

Do not install browser binaries.

Do not depend on browser screenshots for automated acceptance.

Visual/manual QA instructions can be documented for us to perform later.

CLI verification is the required automated approach.

---

# 38. ARC TESTNET PREFLIGHT

Create:

scripts/arc-testnet-preflight.sh

It should verify, without changing state:

- testnet RPC responds
- eth_chainId matches expected Arc Testnet
- USDC contract/predeploy has bytecode
- USDC decimals == 6
- ProofPay deployment address if configured has bytecode
- creator wallet address can be derived from key if key exists
- worker wallet address can be derived from key if key exists
- native balance available for network fees
- ERC-20 USDC balance available for bounty escrow
- no private key is printed

If required test wallets are not configured, report exactly what is missing and exit safely.

---

# 39. ARC TESTNET WALLETS

Use two test accounts for realistic network smoke testing:

ARC_TESTNET_CREATOR_PRIVATE_KEY
ARC_TESTNET_WORKER_PRIVATE_KEY

Never commit these.

Never print these.

Derive and print only public addresses.

Document that both wallets need Arc Testnet funding.

The creator needs test USDC for:

- bounty
- transaction fees

The worker needs enough test USDC/native balance for:

- claim transaction
- submit transaction

Because Arc uses USDC for gas, account for transaction fees separately from the bounty assertion.

When checking payout balance changes, account for worker gas costs correctly rather than assuming:

final balance - initial balance == bounty

A more reliable assertion is to inspect the ProofPay contract state, token transfer receipt/events, and expected payout while accounting for fees appropriately.

---

# 40. ARC TESTNET DEPLOYMENT

Create a Foundry deployment script:

contracts/script/DeployProofPay.s.sol

Deployment should:

1. verify target chain
2. obtain the configured USDC address
3. deploy ProofPay
4. confirm code exists
5. confirm ProofPay.usdc() equals expected address

Create a shell wrapper.

Do not deploy automatically during ordinary tests.

Testnet deployment must be explicitly invoked.

Store resulting deployment metadata under:

deployments/arc-testnet.json

Do not overwrite an existing deployment accidentally without an explicit flag.

---

# 41. ARC TESTNET SMOKE TEST

Create:

scripts/arc-testnet-smoke.sh

or equivalent CLI workflow.

It must execute a real end-to-end lifecycle after ProofPay is deployed.

Creator:
- checks allowance
- approves exact test bounty amount
- creates bounty

Worker:
- claims bounty
- submits a harmless proof URL such as an example repository URL

Creator:
- approves and pays

Then assert:

- transaction receipts succeeded
- task exists
- expected creator is recorded
- expected worker is recorded
- final status == COMPLETED
- escrow no longer remains associated with task
- worker payout occurred

Print:

- task ID
- transaction hashes
- explorer links
- final status

Do not print secrets.

Keep smoke bounty tiny.

---

# 42. TESTNET FAILURE SCENARIOS

Create at least one network-safe script or documented cast commands for:

- create then cancel
- create then claim then allow deadline/refund if practical

Do not waste significant faucet funds.

Most unhappy-path testing should remain local Foundry tests.

Testnet is for Arc-specific compatibility and end-to-end confirmation.

---

# 43. MAINNET MUST REMAIN GATED

DO NOT deploy Mainnet as part of initial implementation.

Create preparation scripts only.

Mainnet deployment must require deliberate invocation.

Create:

scripts/mainnet-preflight.sh

This must perform read-only checks:

- all local tests pass or require a fresh test-all artifact
- git working tree state shown
- production build succeeds
- mainnet RPC chain ID is correct
- expected mainnet USDC address has bytecode
- USDC decimals == 6
- deployer public address
- deployer native balance
- relevant configuration
- no testnet contract address leaking into production config

Do not broadcast anything from preflight.

---

# 44. MAINNET DEPLOYMENT SAFETY GATE

Create:

scripts/mainnet-deploy.sh

It must refuse to run unless a deliberately verbose confirmation variable exists, e.g.:

CONFIRM_ARC_MAINNET_DEPLOYMENT=DEPLOY_PROOFPAY_WITH_REAL_USDC

Also require:

ARC_MAINNET_PRIVATE_KEY

Never default this variable.

Never deploy Mainnet from:

npm install
pnpm build
test-all
CI
Vercel build
postinstall

Mainnet deployment must only occur through the explicit deployment script.

Print a warning that Mainnet uses real USDC.

Print deployer ADDRESS only.

Never echo the private key.

---

# 45. MAINNET DEPLOYMENT IS NOT PART OF CURRENT DONE STATE

For this development session, the MVP counts as complete when:

- local environment works
- contracts are comprehensively tested
- frontend builds and tests
- local integration works
- Arc Testnet deployment/smoke tooling is ready
- actual Arc Testnet smoke passes if funded test credentials are available
- docs are complete
- mainnet scripts/preflight are ready

Do not claim Mainnet deployment occurred unless it actually occurred.

---

# 46. ENVIRONMENT VARIABLES

Create a complete `.env.example`.

Include only variables actually used.

Approximately:

NEXT_PUBLIC_ARC_ENV=testnet

NEXT_PUBLIC_ARC_TESTNET_RPC_URL=
NEXT_PUBLIC_ARC_MAINNET_RPC_URL=

NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS=
NEXT_PUBLIC_PROOFPAY_MAINNET_ADDRESS=

NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=

ARC_TESTNET_RPC_URL=
ARC_TESTNET_CREATOR_PRIVATE_KEY=
ARC_TESTNET_WORKER_PRIVATE_KEY=

ARC_MAINNET_RPC_URL=
ARC_MAINNET_PRIVATE_KEY=

Never place real secrets in `.env.example`.

Document which are:

- required for frontend
- required for testnet deployment
- required for smoke tests
- mainnet-only

---

# 47. SECRET HANDLING

Ensure .gitignore contains:

.env
.env.local
.env.*.local
private deployment secret files

Never log:

PRIVATE_KEY
mnemonic
seed phrase

Before completion, inspect tracked files for obvious secret leaks.

Create a lightweight script if helpful:

scripts/check-secrets.sh

It does not need to replace professional secret-scanning software.

---

# 48. README

README.md must be high quality.

It should contain:

# ProofPay

One-sentence description.

## What it does

Explain:

- creator posts outcome
- creator escrows USDC
- worker claims
- worker submits proof
- creator accepts
- contract pays worker

## Why Arc

Explain concretely:

- USDC-focused economic activity
- USDC pays network fees
- familiar EVM development environment
- useful fit for small programmable payments

Do not overclaim.

## Architecture

Simple diagram:

Browser
↓
Next.js + wagmi/viem
↓
ProofPay.sol
↓
Arc USDC

## Contract lifecycle

CREATE
→ CLAIM
→ SUBMIT
→ APPROVE
→ PAY

Include cancellation/rejection/expiry paths.

## Trust model

Clearly explain:

- creator decides whether submitted work is accepted
- no decentralized arbitration in MVP
- blockchain escrow guarantees custody/state transitions, not correctness of work
- smart-contract risk exists

## Arc USDC model

Explain:

- one underlying USDC balance
- native 18-decimal representation
- ERC-20 6-decimal interface
- ProofPay uses ERC-20 interface for escrow

## Local development

Exact commands.

## Tests

Explain:

./scripts/test-all.sh

and each major script.

## Arc Testnet

Funding, environment, preflight, deployment, smoke test.

## Mainnet

Explain mainnet is deliberately gated.

## Deployment addresses

Link to deployment JSON files when deployments exist.

## Security

Link SECURITY.md.

## License

Use an appropriate permissive license such as MIT unless the repository already specifies one.

---

# 49. ARCHITECTURE DOCUMENTATION

Create:

docs/ARCHITECTURE.md

Explain:

- frontend structure
- chain configuration
- wallet interaction
- contract structure
- escrow model
- lifecycle/state machine
- data loading
- why there is no backend
- why metadata is onchain in MVP
- Arc-specific USDC representation
- deployment config

Include a Mermaid diagram if GitHub rendering supports it.

Keep the diagram simple.

---

# 50. TESTING DOCUMENTATION

Create:

docs/TESTING.md

Document:

- contract tests
- fuzz tests
- frontend unit tests
- local integration
- Arc Testnet preflight
- Arc Testnet smoke test
- what is and is not tested
- why Playwright is intentionally not part of the stack
- manual visual QA checklist

Provide exact commands.

---

# 51. DEPLOYMENT DOCUMENTATION

Create:

docs/DEPLOYMENT.md

Separate:

## Local

## Arc Testnet

## Arc Mainnet

For each, document:

- prerequisites
- environment variables
- preflight
- deployment command
- verification steps
- deployment metadata
- frontend configuration

Mainnet section must emphasize:

- real USDC
- irreversible transactions
- run complete test suite first
- verify current official Arc network information
- use fresh production build
- verify contract bytecode after deployment
- run tiny real-value smoke transaction only after deployment has been reviewed

---

# 52. SECURITY DOCUMENTATION

Create:

SECURITY.md

Cover:

- no admin withdrawal
- fixed USDC contract
- SafeERC20
- state-transition authorization
- reentrancy protection
- exact approvals in frontend
- no upgradeability
- no dispute arbitration
- creator-controlled rejection
- deadline behavior
- known limitations
- smart-contract risk
- mainnet caution

Do not describe the contract as formally audited.

Do not claim "secure" simply because tests pass.

Say "not professionally audited" unless it later receives an audit.

---

# 53. GRANT SUBMISSION DOCUMENT

Create:

docs/GRANT_SUBMISSION.md

Prepare editable material for the Arc microgrant submission.

Include:

## Name
ProofPay

## Tagline
Outcome-based USDC bounties on Arc.

## Short description
Approximately 2-3 sentences.

## Problem
Small internet-native jobs are often too small for conventional invoicing/payment workflows.

## Solution
Creator escrows USDC, worker claims and submits work, creator approves, contract settles automatically.

## Why Arc
Tie the product specifically to stablecoin-native network economics and fast settlement.

## What is working
Use only facts verified by the repository.

## Tech stack

## Contract address
Placeholder only until an actual deployment exists.

Use:
NOT DEPLOYED YET

Do not invent addresses.

## Demo URL
NOT DEPLOYED YET unless actually deployed.

## Repository
Use actual repo URL if available; otherwise clearly mark placeholder.

## Mainnet evidence checklist

- deployed contract
- explorer URL
- create transaction
- claim transaction
- submit transaction
- payout transaction
- live frontend
- public repository

Do not fabricate any of these.

---

# 54. DEMO SCRIPT

Create:

docs/DEMO.md

Write a concise 45-60 second human demo flow.

Example:

1. Open ProofPay
2. Connect creator wallet
3. Create 1 USDC bounty
4. Show escrow transaction
5. Switch to worker wallet
6. Claim
7. Submit proof URL
8. Switch back to creator
9. Approve
10. Show worker paid
11. Show Arc explorer transaction

Keep narration factual and short.

---

# 55. RELEASE CHECKLIST

Create:

docs/RELEASE_CHECKLIST.md

Include checkboxes for:

Contract:
- formatting
- build
- unit tests
- fuzz tests
- local lifecycle

Frontend:
- lint
- typecheck
- unit tests
- production build
- mobile manual check
- desktop manual check
- wallet rejection states
- RPC failure state
- empty state

Testnet:
- RPC verified
- chain ID verified
- USDC verified
- deployment verified
- full smoke test
- explorer links checked

Documentation:
- README
- architecture
- testing
- security
- deployment
- grant text
- demo

Mainnet:
- intentionally unchecked until later

---

# 56. GITHUB ACTIONS CI

Create a simple GitHub Actions workflow.

On pull request/push:

- install Node/pnpm
- install dependencies
- install Foundry
- run deterministic local verification

Prefer calling:

./scripts/test-all.sh

rather than duplicating the entire test implementation in YAML.

Do not use private keys in normal CI.

Do not run Arc Testnet deployment in CI.

Do not run Mainnet anything in CI.

---

# 57. DEPENDENCY DISCIPLINE

Use established dependencies only.

Before adding a library, ask:

Can this be done simply without another dependency?

Do not install packages merely for trivial formatting/helpers.

Avoid dependency duplication.

Use one package manager.

Prefer pnpm.

Commit the lockfile.

---

# 58. ERROR HANDLING

Frontend must gracefully handle:

- wallet missing
- wallet disconnected
- wrong network
- user rejects transaction
- insufficient USDC
- insufficient fee balance
- allowance insufficient
- RPC unavailable
- contract read failure
- transaction reverted
- expired task
- already-claimed task
- stale UI state

After a write receipt, invalidate/refetch the necessary contract queries.

Do not require page refresh for normal operation.

---

# 59. EXPLORER LINKS

Centralize explorer URL construction.

Provide links for:

- connected addresses where useful
- contract address
- transaction hashes

Do not hard-code explorer URLs throughout components.

---

# 60. DATE HANDLING

Store blockchain timestamps as Unix seconds.

Frontend should:

- clearly distinguish timestamps from JS milliseconds
- display deadlines in user's local timezone
- show an absolute date
- optionally show relative time

Do not calculate contract authorization based only on browser time.

Contract rules always use block.timestamp.

Browser time is display-only.

---

# 61. AMOUNT HANDLING

Never use JavaScript floating-point arithmetic for raw USDC values.

For input:

string
→ validate decimal precision <= 6
→ parseUnits(input, 6)
→ bigint

For display:

bigint
→ formatUnits(value, 6)

Do not convert onchain amounts to Number unless absolutely safe and presentation-only.

Contract values stay uint256/bigint.

---

# 62. STATUS LOGIC

Define state logic in one shared frontend location.

Create utilities like:

getTaskStatusLabel()
getTaskStatusTone()
getAvailableTaskActions()

Do not scatter:

status === 2

through components.

Use named enum mappings.

Tests must cover frontend enum mapping against Solidity enum order.

---

# 63. LOADING AND EMPTY STATES

No blank screens.

Examples:

No bounties yet.

"Be the first to post an outcome."

No wallet:

"Connect a wallet to create or claim bounties."

RPC issue:

"We couldn't reach Arc right now. Retry."

Do not blame the user's wallet for generic RPC failures.

---

# 64. MOBILE

The application must remain fully usable at approximately 375px viewport width.

Tables that become awkward should become stacked cards or responsive rows.

Buttons must remain tappable.

Wallet addresses must not overflow.

Proof URLs must wrap safely.

---

# 65. PERFORMANCE

Avoid unnecessary optimization.

But:

- batch reads where useful
- avoid polling every second
- avoid huge dependency bundles
- lazy-load optional dialogs if natural
- fetch a limited task window

Arc finality is fast, but do not assume transaction success before receipt.

---

# 66. COPY STYLE

Use plain language.

Prefer:

Create bounty
Claim bounty
Submit work
Approve & pay
Reject & refund
Cancel bounty

Avoid:

Initialize decentralized work order
Execute trustless settlement primitive
Commence bounty lifecycle

Users should understand the product without blockchain expertise.

---

# 67. NO FAKE CONTENT

Do not include:

- fake transaction metrics
- fake users
- fake TVL
- fake bounty volume
- fake testimonials
- fake partners
- fake security audit
- fake grant award
- fake mainnet address
- fake GitHub stats

If data does not exist, show a good empty state.

---

# 68. ARC-SPECIFIC VALIDATION

Local EVM testing alone is NOT enough because Arc has protocol-specific behavior.

Therefore the development progression is:

1. Foundry unit tests
2. local Anvil integration
3. frontend tests/build
4. Arc Testnet preflight
5. Arc Testnet deployment
6. Arc Testnet full lifecycle smoke test
7. manual UI QA against testnet
8. only later consider Arc Mainnet

Document this explicitly.

---

# 69. MAINNET RELEASE STRATEGY FOR LATER

Prepare for, but do not execute, this eventual sequence:

1. freeze feature work
2. run ./scripts/test-all.sh
3. run Arc Testnet smoke again
4. manually inspect ProofPay.sol
5. inspect deployment diff
6. verify official Arc Mainnet config
7. run mainnet preflight
8. fund dedicated deployer with minimal required USDC
9. deploy ProofPay
10. record deployment metadata
11. verify explorer bytecode/source if officially supported
12. configure production frontend
13. production build
14. deploy frontend
15. create a tiny real mainnet bounty
16. second wallet claims
17. submits proof
18. creator approves
19. verify payout
20. record explorer evidence for grant submission

Do not perform these steps automatically now.

---

# 70. DEVELOPMENT STATUS FILE

Create:

docs/BUILD_STATUS.md

Maintain it while working.

Suggested format:

## Completed

## In progress

## Blocked externally

## Remaining

If testnet deployment cannot run because funded private keys are not supplied, that is an external block, not a software failure.

Everything else should still be completed.

---

# 71. DEVELOPMENT EXECUTION ORDER

Follow this order.

## Phase 0 — Discovery

- inspect repository
- inspect available Node/pnpm/Foundry versions
- verify current Arc documentation
- create project skeleton
- create BUILD_STATUS.md

Run setup verification.

## Phase 1 — Contract

- MockUSDC
- ProofPay
- unit tests
- fuzz tests
- deployment script

Run:

./scripts/test-contracts.sh

Fix everything before continuing.

## Phase 2 — Local integration

- Anvil script
- complete happy path
- cancel/refund path

Run:

./scripts/test-local-integration.sh

Fix everything.

## Phase 3 — Frontend foundation

- Next.js
- Tailwind
- components
- chain config
- ABI sync
- wallet provider
- read hooks

Run:

./scripts/test-web.sh

## Phase 4 — User flows

- homepage
- create
- detail
- allowance flow
- claim
- release
- submit
- approve
- reject
- cancel/refund
- transaction states

Run frontend tests/build repeatedly.

## Phase 5 — Testnet tooling

- preflight
- deploy
- smoke test
- deployment metadata

Run preflight.

If funded secrets exist:
deploy and smoke test.

If not:
leave software ready and document exact external requirement.

## Phase 6 — Documentation

Finish all required docs.

## Phase 7 — Final quality pass

Run:

./scripts/test-all.sh

Then inspect:

git diff

Check:

- TODO
- FIXME
- placeholder
- fake address
- console.log
- dead code
- secret leaks
- unused dependency
- commented-out implementation

Remove inappropriate leftovers.

---

# 72. FINAL ACCEPTANCE CRITERIA

Do not report the project "complete" until all applicable items below are true.

## Contract

- compiles
- formatted
- comprehensive tests pass
- fuzz tests pass
- lifecycle works locally
- no admin withdrawal
- exact USDC accounting

## Frontend

- lint passes
- typecheck passes
- unit tests pass
- production build passes
- no fake actions
- every visible action is wired
- valid state transitions reflected correctly
- wrong-network handling exists
- mobile layout implemented

## Integration

- local full lifecycle passes from script
- cancellation/refund path passes
- Arc Testnet preflight exists and works
- Arc Testnet smoke works if credentials/funds are available

## Documentation

- README complete
- architecture complete
- testing complete
- deployment complete
- security complete
- demo complete
- grant submission draft complete
- release checklist complete

## Operations

- test-all script works
- CI uses test-all
- secrets ignored
- mainnet deployment gated
- no Mainnet deployment executed unintentionally

---

# 73. FINAL REPORT FORMAT

At the end, give me a concise engineering report containing:

## Built

What was implemented.

## Contract

Contract architecture and major behavior.

## Tests

Exact commands run and pass/fail results.

Report real numbers when available, such as:

- Foundry tests: X passed
- frontend tests: X passed
- build: passed
- local lifecycle: passed

Do not invent counts.

## Arc Testnet

Say exactly one of:

- deployed and smoke tested successfully, with addresses and transaction hashes

OR

- deployment ready but blocked because testnet credentials/funding were not supplied

Do not call it deployed when it is not.

## Mainnet

Explicitly state:

Not deployed yet.

unless we separately and intentionally deployed it.

## Files to review

List the most important files.

## Remaining manual checks

Only genuine manual tasks, such as:

- visually inspect UI
- provide funded Arc Testnet wallets
- deploy frontend
- later perform explicit Mainnet deployment

---

# 74. IMPORTANT ENGINEERING BEHAVIOR

While building:

Do not stop merely because one approach fails.

Diagnose the issue and try a correct alternative.

Do not leave a broken build.

Do not hide TypeScript errors.

Do not disable lint rules to bypass genuine errors.

Do not mark tests skipped simply because they fail.

Do not use `any` everywhere to silence types.

Do not replace real contract interactions with mocks in production code.

Do not install Playwright.

Do not deploy Mainnet.

Do not expose secrets.

Do not invent network information.

Do not invent deployment results.

Do not fabricate grant evidence.

Do not introduce unnecessary scope.

The target is a **small, clean, working, well-tested ProofPay MVP** that can later be deployed to Arc Mainnet with confidence.

Begin now with Phase 0 and continue through all possible phases autonomously.