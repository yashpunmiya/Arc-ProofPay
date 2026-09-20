import { NextResponse } from "next/server";
import { proofPayAddress } from "@/lib/chain";
import { proofPayAbi, type Task } from "@/lib/proofpay";
import { publicClient } from "@/lib/public-client";

export const dynamic = "force-dynamic";

function serializeTask(task: Task) {
  return {
    ...task,
    id: task.id.toString(),
    amount: task.amount.toString(),
    deadline: task.deadline.toString(),
    createdAt: task.createdAt.toString(),
    claimedAt: task.claimedAt.toString(),
    submittedAt: task.submittedAt.toString(),
  };
}

export async function GET(request: Request) {
  const address = proofPayAddress;
  if (!address) return NextResponse.json({ error: "ProofPay Mainnet address is not configured." }, { status: 503 });
  try {
    const requestedId = new URL(request.url).searchParams.get("id");
    if (requestedId) {
      if (!/^\d+$/.test(requestedId) || requestedId === "0") return NextResponse.json({ error: "Invalid task ID." }, { status: 400 });
      const task = await publicClient.readContract({ address, abi: proofPayAbi, functionName: "getTask", args: [BigInt(requestedId)] });
      return NextResponse.json({ task: serializeTask(task as unknown as Task) }, { headers: { "Cache-Control": "public, s-maxage=5, stale-while-revalidate=20" } });
    }
    const count = await publicClient.readContract({ address, abi: proofPayAbi, functionName: "taskCount" });
    const total = Number(count);
    const ids = Array.from({ length: Math.min(total, 200) }, (_, index) => BigInt(total - index));
    const tasks = await Promise.all(ids.map((id) => publicClient.readContract({ address, abi: proofPayAbi, functionName: "getTask", args: [id] })));
    return NextResponse.json({ tasks: tasks.map((task) => serializeTask(task as unknown as Task)), total }, { headers: { "Cache-Control": "public, s-maxage=5, stale-while-revalidate=20" } });
  } catch (error) {
    console.error("ProofPay public RPC read failed", error instanceof Error ? error.message : "unknown error");
    return NextResponse.json({ error: "Arc Mainnet data is temporarily unavailable." }, { status: 503 });
  }
}
