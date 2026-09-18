import Link from "next/link";
import { ArrowUpRight, CheckCircle2, CircleDollarSign, Clock3 } from "lucide-react";
import { TaskList } from "@/components/task-list";

export default function Home() {
  return <>
    <section className="grid gap-10 border-b rule pb-14 pt-4 lg:grid-cols-[1.15fr_.85fr] lg:items-end lg:gap-20">
      <div>
        <p className="eyebrow">Outcome-based payments on Arc</p>
        <h1 className="mt-5 max-w-3xl text-5xl font-semibold leading-[.98] tracking-[-.055em] md:text-7xl">Small work.<br /><span className="text-stone-500">Settled properly.</span></h1>
        <p className="mt-7 max-w-lg text-lg leading-8 text-stone-600">Post a clear outcome, escrow USDC, and pay when the work is accepted. ProofPay keeps the agreement and settlement in one place.</p>
        <div className="mt-8 flex flex-wrap gap-3"><Link href="/create" className="group inline-flex min-h-11 items-center gap-2 rounded-md bg-[rgb(var(--ink))] px-5 py-3 text-sm font-semibold text-white hover:bg-[rgb(var(--accent))]">Create a bounty <ArrowUpRight aria-hidden="true" className="h-4 w-4" /></Link><a href="#bounties" className="inline-flex min-h-11 items-center rounded-md border rule px-5 py-3 text-sm font-semibold hover:bg-white">Browse work</a></div>
      </div>
      <div className="surface rounded-xl p-6 shadow-[0_18px_50px_rgba(25,31,35,.06)] lg:mb-1">
        <div className="flex items-center justify-between border-b rule pb-4"><p className="text-sm font-semibold">How it works</p><span className="rounded-full bg-[rgb(var(--accent-soft))] px-2.5 py-1 text-xs font-semibold text-[rgb(var(--accent))]">Onchain</span></div>
        <ol className="mt-2 divide-y rule"><li className="flex gap-4 py-4"><CircleDollarSign className="mt-0.5 h-5 w-5 text-[rgb(var(--accent))]" aria-hidden="true" /><div><p className="text-sm font-semibold">Creator escrows USDC</p><p className="mt-1 text-sm leading-6 text-stone-500">The bounty stays locked in the contract.</p></div></li><li className="flex gap-4 py-4"><Clock3 className="mt-0.5 h-5 w-5 text-[rgb(var(--accent))]" aria-hidden="true" /><div><p className="text-sm font-semibold">Worker delivers proof</p><p className="mt-1 text-sm leading-6 text-stone-500">A claim and proof URL make progress visible.</p></div></li><li className="flex gap-4 pt-4"><CheckCircle2 className="mt-0.5 h-5 w-5 text-[rgb(var(--accent))]" aria-hidden="true" /><div><p className="text-sm font-semibold">Creator approves and pays</p><p className="mt-1 text-sm leading-6 text-stone-500">One confirmed transaction settles the outcome.</p></div></li></ol>
      </div>
    </section>
    <section id="bounties" className="pt-10"><div className="mb-5 flex items-end justify-between gap-4"><div><p className="eyebrow">Live board</p><h2 className="mt-2 text-2xl font-semibold tracking-tight">Recent bounties</h2></div><p className="hidden text-sm text-stone-500 sm:block">Open, active, and settled on Arc</p></div><TaskList /></section>
  </>;
}
