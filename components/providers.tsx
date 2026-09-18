"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider, createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { arcTestnet } from "@/lib/chain";
import { ChainSync } from "@/components/chain-sync";
const rpcUrl = process.env.NEXT_PUBLIC_ARC_TESTNET_RPC_URL || "https://rpc.testnet.arc.network";
const config=createConfig({chains:[arcTestnet],connectors:[injected()],transports:{[arcTestnet.id]:http(rpcUrl,{retryCount:4,retryDelay:1000,timeout:15_000})}});
const client=new QueryClient();
export function Providers({children}:{children:React.ReactNode}) { return <WagmiProvider config={config}><QueryClientProvider client={client}><ChainSync/>{children}</QueryClientProvider></WagmiProvider>; }
