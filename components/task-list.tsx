"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { formatUnits } from "viem";
import { useAccount } from "wagmi";
import { useTasks } from "@/hooks/use-tasks";
import { proofPayAddress } from "@/lib/chain";
import { Status, statusLabel, statusTone, type TaskStatus } from "@/lib/proofpay";

const filters = [{ label: "Open", value: "open" }, { label: "Active", value: "active" }, { label: "Completed", value: "completed" }, { label: "All", value: "all" }] as const;
type FilterValue = (typeof filters)[number]["value"];

function readFilter(value: string | null): FilterValue {
  return filters.some((filter) => filter.value === value) ? (value as FilterValue) : "all";
}

export function TaskList() {
  const { tasks, isLoading, error, refetch } = useTasks();
  const { address } = useAccount();
  const [selected, setSelected] = useState<FilterValue>("all");
  const [mine, setMine] = useState<string | null>(null);
  useEffect(() => {
    const syncFromUrl = () => {
      const params = new URLSearchParams(window.location.search);
      setSelected(readFilter(params.get("filter")));
      setMine(params.get("mine"));
    };
    syncFromUrl();
    window.addEventListener("popstate", syncFromUrl);
    return () => window.removeEventListener("popstate", syncFromUrl);
  }, []);
  const chooseFilter = (value: FilterValue) => {
    setSelected(value);
    setMine(null);
    window.history.replaceState(null, "", value === "all" ? "/#bounties" : `/?filter=${value}#bounties`);
  };
  const chooseMine = () => {
    setSelected("all");
    setMine("created");
    window.history.replaceState(null, "", "/?mine=created#bounties");
  };
  const shown = tasks.filter((task) => {
    if (mine === "claimed") return task.worker.toLowerCase() === address?.toLowerCase();
    if (mine === "created") return task.creator.toLowerCase() === address?.toLowerCase();
    return selected === "all" || (selected === "open" && task.status === Status.OPEN) || (selected === "active" && (task.status === Status.CLAIMED || task.status === Status.SUBMITTED)) || (selected === "completed" && task.status === Status.COMPLETED);
  });
  if (!proofPayAddress) return <div className="surface rounded-xl p-6"><p className="font-semibold">Contract not configured</p><p className="mt-1 text-sm text-stone-600">Configure the ProofPay address for the active Arc network.</p></div>;
  return <div>
    <div className="mb-5 flex flex-wrap items-center justify-between gap-3"><div className="flex max-w-full flex-wrap gap-1 rounded-xl border rule bg-white p-1" role="group" aria-label="Bounty filters">{filters.map((filter) => <button type="button" key={filter.value} onClick={() => chooseFilter(filter.value)} aria-pressed={selected === filter.value && !mine} className={`min-h-10 rounded-lg px-3 text-sm font-medium ${selected === filter.value && !mine ? "bg-[rgb(var(--ink))] text-white shadow-sm" : "text-stone-600 hover:bg-stone-100"}`}>{filter.label}</button>)}{address && <button type="button" onClick={chooseMine} aria-pressed={mine === "created"} className={`min-h-10 rounded-lg border-l rule px-3 text-sm font-medium ${mine === "created" ? "bg-[rgb(var(--accent-soft))] text-[rgb(var(--accent))]" : "text-stone-600 hover:bg-stone-100"}`}>Created by me</button>}</div><span className="text-xs text-stone-500">{shown.length} {shown.length === 1 ? "bounty" : "bounties"}</span></div>
    {isLoading && <div className="space-y-3">{[1, 2, 3].map((id) => <div key={id} className="h-32 animate-pulse rounded-xl border rule bg-white/60" />)}</div>}
    {error && <div className="rounded-xl border border-red-300 bg-red-50 p-5"><p className="font-semibold text-red-900">Couldn&apos;t load the board</p><p className="mt-1 text-sm text-red-800">The Arc RPC may be unavailable. Try again in a moment.</p><button onClick={() => refetch()} className="mt-4 min-h-10 rounded-md border border-red-400 px-3 text-sm text-red-900">Retry</button></div>}
    {!isLoading && !error && shown.length === 0 && <div className="rounded-xl border border-dashed rule bg-white/40 px-6 py-14 text-center"><p className="font-semibold">No bounties here yet.</p><p className="mt-1 text-sm text-stone-600">Post the first clear outcome and let someone pick it up.</p><Link href="/create" className="mt-5 inline-flex min-h-10 items-center rounded-md bg-[rgb(var(--ink))] px-4 text-sm font-semibold text-white">Create a bounty</Link></div>}
    <div className="space-y-3">{shown.slice(0, 50).map((task) => <TaskRow key={task.id.toString()} task={task} />)}</div>
  </div>;
}

function TaskRow({ task }: { task: { id: bigint; title: string; description: string; amount: bigint; status: TaskStatus; deadline: bigint; creator: string; worker: string } }) {
  return <article className="surface group rounded-xl p-5 hover:bg-white"><div className="flex flex-wrap items-start justify-between gap-4"><div className="min-w-0 flex-1"><div className="flex items-center gap-2"><span className={`h-2 w-2 rounded-full ${task.status === Status.OPEN ? "bg-emerald-500" : task.status === Status.COMPLETED ? "bg-stone-400" : "bg-amber-500"}`} aria-hidden="true" /><h3 className="truncate font-semibold"><Link href={`/bounty/${task.id}`} className="group-hover:text-[rgb(var(--accent))]">{task.title}</Link></h3></div><p className="mt-2 line-clamp-2 max-w-2xl text-sm leading-6 text-stone-600">{task.description || "No additional description."}</p></div><p className="font-mono text-lg font-semibold tabular-nums">{formatUnits(task.amount, 6)} <span className="font-sans text-xs font-medium text-stone-500">USDC</span></p></div><div className="mt-5 flex flex-wrap items-center gap-x-5 gap-y-2 border-t rule pt-3 text-xs text-stone-500"><span className={`rounded-full px-2 py-1 font-medium ${statusTone(task.status)}`}>{statusLabel(task.status)}</span><span>Due {new Date(Number(task.deadline) * 1000).toLocaleDateString()}</span><span>From {task.creator.slice(0, 6)}…{task.creator.slice(-4)}</span><Link className="ml-auto min-h-10 rounded-md border rule px-3 py-2 text-sm font-medium text-stone-700 hover:border-stone-500 hover:text-[rgb(var(--accent))]" href={`/bounty/${task.id}`}>View details</Link></div></article>;
}

