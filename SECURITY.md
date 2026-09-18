# Security

ProofPay has a fixed immutable USDC token, no owner, no upgradeability, and no admin withdrawal. All token movements use SafeERC20 and state is updated before transfers under reentrancy protection.

The creator controls submitted-work acceptance and may reject/refund it. This is escrow custody and state-transition enforcement, not trustless arbitration. Deadlines only apply to claiming/submission; timely submitted work remains reviewable after its deadline.

Frontend approvals are exact amounts. The contract has not been professionally audited. Do not use meaningful funds without independent review.
