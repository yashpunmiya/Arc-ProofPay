import type { Address, Hex } from "viem";
import { encodeFunctionData } from "viem";
import { proofPayAbi, erc20Abi } from "./proofpay.ts";

// Explicit bounds avoid Arc RPC simulation false-negatives (USDC blocklist probe)
// while remaining close to observed Mainnet receipts with production headroom.
export const PROOFPAY_GAS_LIMITS = {
  approve: 90_000n,
  createTask: 320_000n,
  claimTask: 120_000n,
  releaseClaim: 120_000n,
  submitProof: 150_000n,
  approveAndPay: 120_000n,
  rejectAndRefund: 160_000n,
  cancelTask: 140_000n,
  refundExpiredTask: 140_000n,
} as const;

export type ProofPayWriteName = Exclude<keyof typeof PROOFPAY_GAS_LIMITS, "approve">;

type ProofPayArgs =
  | { functionName: "createTask"; args: readonly [string, string, bigint, bigint] }
  | { functionName: "submitProof"; args: readonly [bigint, string] }
  | { functionName: "rejectAndRefund"; args: readonly [bigint, string] }
  | { functionName: Exclude<ProofPayWriteName, "createTask" | "submitProof" | "rejectAndRefund">; args: readonly [bigint] };

export function buildProofPayWrite(address: Address, input: ProofPayArgs): any {
  return {
    address,
    abi: proofPayAbi,
    functionName: input.functionName,
    args: input.args,
    gas: PROOFPAY_GAS_LIMITS[input.functionName],
  } as const;
}

export function buildUsdcApproval(address: Address, spender: Address, amount: bigint) {
  return {
    address,
    abi: erc20Abi,
    functionName: "approve" as const,
    args: [spender, amount] as const,
    gas: PROOFPAY_GAS_LIMITS.approve,
  } as const;
}

export function encodeProofPayWrite(input: ProofPayArgs): Hex {
  return encodeFunctionData({ abi: proofPayAbi, functionName: input.functionName, args: input.args });
}
