"use client";

import { TaskDetail } from "@/components/task-detail";
import { useTask } from "@/hooks/use-tasks";
import type { Task } from "@/lib/proofpay";

export function BountyView({ id }: { id: string }) {
  const result = useTask(BigInt(id));
  if (result.isLoading) return <div className="h-64 animate-pulse rounded-lg bg-stone-200" />;
  if (result.error || !result.data) return <p className="rounded-lg border border-red-300 bg-red-50 p-5">Couldn’t load this bounty. Check the ID and Arc connection.</p>;
  return <TaskDetail task={result.data as Task} />;
}
