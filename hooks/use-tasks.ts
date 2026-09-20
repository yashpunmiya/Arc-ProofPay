"use client";

import { useQuery } from "@tanstack/react-query";
import { proofPayAddress } from "@/lib/chain";
import type { Task } from "@/lib/proofpay";

type WireTask = Omit<Task, "id" | "amount" | "deadline" | "createdAt" | "claimedAt" | "submittedAt"> & {
  id: string; amount: string; deadline: string; createdAt: string; claimedAt: string; submittedAt: string;
};

const boardKey = ["proofpay-board", proofPayAddress] as const;

function hydrateTask(task: WireTask): Task {
  return { ...task, id: BigInt(task.id), amount: BigInt(task.amount), deadline: BigInt(task.deadline), createdAt: BigInt(task.createdAt), claimedAt: BigInt(task.claimedAt), submittedAt: BigInt(task.submittedAt) };
}

async function requestJson<T>(path: string): Promise<T> {
  const response = await fetch(path, { headers: { accept: "application/json" } });
  const body = await response.json() as T & { error?: string };
  if (!response.ok) throw new Error(body.error || "Arc Mainnet data is temporarily unavailable.");
  return body;
}

export function useTasks() {
  const query = useQuery({ queryKey: boardKey, queryFn: async () => (await requestJson<{ tasks: WireTask[] }>("/api/tasks")).tasks.map(hydrateTask), enabled: !!proofPayAddress, staleTime: 8_000, retry: 3, retryDelay: (attempt) => Math.min(1_000 * 2 ** attempt, 5_000), refetchInterval: 15_000 });
  return { tasks: query.data || [], isLoading: query.isLoading, error: query.error, refetch: () => { void query.refetch(); } };
}

export function useTask(id: bigint) {
  return useQuery({ queryKey: [...boardKey, "task", id.toString()], queryFn: async () => hydrateTask((await requestJson<{ task: WireTask }>(`/api/tasks?id=${id}`)).task), enabled: !!proofPayAddress && id > 0n, staleTime: 8_000, retry: 3 });
}
