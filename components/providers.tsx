"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider, createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { arcChain } from "@/lib/chain";
import { ChainSync } from "@/components/chain-sync";
const rpcUrl = arcChain.rpcUrls.default.http[0];
const config=createConfig({chains:[arcChain],connectors:[injected()],transports:{5042:http(rpcUrl,{retryCount:4,retryDelay:1000,timeout:15_000}),5042002:http(process.env.NEXT_PUBLIC_ARC_TESTNET_RPC_URL || "https://rpc.testnet.arc.network",{retryCount:4,retryDelay:1000,timeout:15_000})}});
const client=new QueryClient();
export function Providers({children}:{children:React.ReactNode}) { return <WagmiProvider config={config}><QueryClientProvider client={client}><ChainSync/>{children}</QueryClientProvider></WagmiProvider>; }
