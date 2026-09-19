"use client";

import { useQuery } from "@tanstack/react-query";
import { proofPayAbi, type Task } from "@/lib/proofpay";
import { proofPayAddress } from "@/lib/chain";
import { publicClient } from "@/lib/public-client";

const boardKey = ["proofpay-board", proofPayAddress, publicClient.chain.id] as const;

async function readBoard(): Promise<Task[]> {
  const address = proofPayAddress;
  if (!address) return [];
  const count = await publicClient.readContract({ address, abi: proofPayAbi, functionName: "taskCount" });
  const total = Number(count);
  if (total === 0) return [];
  const ids = Array.from({ length: Math.min(total, 200) }, (_, i) => BigInt(total - i));
  const results = await Promise.all(ids.map((id) => publicClient.readContract({ address, abi: proofPayAbi, functionName: "getTask", args: [id] })));
  return results as unknown as Task[];
}

export function useTasks() {
  const query = useQuery({ queryKey: boardKey, queryFn: readBoard, enabled: !!proofPayAddress, staleTime: 8_000, retry: 3, retryDelay: (attempt) => Math.min(1_000 * 2 ** attempt, 5_000), refetchInterval: 15_000 });
  return { tasks: query.data || [], isLoading: query.isLoading, error: query.error, refetch: () => { void query.refetch(); } };
}

export function useTask(id: bigint) {
  const address = proofPayAddress;
  return useQuery({ queryKey: [...boardKey, "task", id.toString()], queryFn: () => publicClient.readContract({ address: address!, abi: proofPayAbi, functionName: "getTask", args: [id] }), enabled: !!address, staleTime: 8_000, retry: 3 });
}
