"use client";

import { useReadContract, useReadContracts } from "wagmi";
import { proofPayAbi, type Task } from "@/lib/proofpay";
import { proofPayAddress } from "@/lib/chain";

export function useTasks() {
  const count = useReadContract({ address: proofPayAddress, abi: proofPayAbi, functionName: "taskCount", query: { enabled: !!proofPayAddress } });
  const ids = Array.from({ length: Number(count.data || 0n) }, (_, i) => BigInt(Number(count.data || 0n) - i));
  const reads = useReadContracts({ contracts: ids.map((id) => ({ address: proofPayAddress!, abi: proofPayAbi, functionName: "getTask", args: [id] })), query: { enabled: ids.length > 0 } });
  return { tasks: reads.data?.flatMap((x) => x.status === "success" ? [x.result as unknown as Task] : []) || [], isLoading: count.isLoading || reads.isLoading, error: count.error || reads.error, refetch: () => { void count.refetch(); void reads.refetch(); } };
}

export function useTask(id: bigint) {
  return useReadContract({ address: proofPayAddress, abi: proofPayAbi, functionName: "getTask", args: [id], query: { enabled: !!proofPayAddress } });
}
