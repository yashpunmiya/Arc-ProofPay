"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useAccount, useConnect, useDisconnect, useSwitchChain } from "wagmi";
import { arcTestnet } from "@/lib/chain";

const short = (address: string) => `${address.slice(0, 6)}…${address.slice(-4)}`;

export function Header() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  const { address, chainId, isConnecting } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChain } = useSwitchChain();
  if (!mounted) return <header className="border-b rule bg-[rgb(var(--paper))]"><div className="mx-auto flex max-w-6xl items-center gap-5 px-4 py-4 md:px-6"><Link href="/" className="mr-auto flex items-center gap-2 text-lg font-semibold tracking-tight"><span className="flex h-7 w-7 items-center justify-center rounded-md bg-[rgb(var(--accent))] text-xs font-bold text-white">P</span>ProofPay</Link><span className="h-10 w-32 animate-pulse rounded-md bg-stone-200" aria-hidden="true" /></div></header>;
  return <header className="border-b rule bg-[rgb(var(--paper))]"><div className="mx-auto flex max-w-6xl items-center gap-5 px-4 py-4 md:px-6"><Link href="/" className="mr-auto flex items-center gap-2 text-lg font-semibold tracking-tight"><span className="flex h-7 w-7 items-center justify-center rounded-md bg-[rgb(var(--accent))] text-xs font-bold text-white">P</span>ProofPay</Link><nav aria-label="Main navigation" className="hidden items-center gap-6 text-sm text-stone-600 sm:flex"><Link className="hover:text-[rgb(var(--accent))]" href="/">Bounties</Link><Link className="hover:text-[rgb(var(--accent))]" href="/?mine=claimed">My work</Link></nav><span className="hidden items-center gap-2 text-xs text-stone-600 md:flex"><span className={`h-2 w-2 rounded-full ${chainId === arcTestnet.id ? "bg-emerald-500" : "bg-amber-500"}`} aria-hidden="true" />{chainId === arcTestnet.id ? "Arc Testnet" : "Network needed"}</span>{address ? <button onClick={() => disconnect()} className="min-h-10 rounded-md border rule bg-white px-3 text-sm font-medium hover:border-stone-400">{short(address)}</button> : <button disabled={isConnecting} onClick={() => connect({ connector: connectors[0] })} className="min-h-10 rounded-md bg-[rgb(var(--ink))] px-4 text-sm font-semibold text-white hover:bg-[rgb(var(--accent))] disabled:opacity-60">{isConnecting ? "Connecting…" : "Connect wallet"}</button>}{address && chainId !== arcTestnet.id && <button onClick={() => switchChain({ chainId: arcTestnet.id })} className="min-h-10 rounded-md border border-amber-600 px-3 text-sm text-amber-800">Switch network</button>}</div></header>;
}
