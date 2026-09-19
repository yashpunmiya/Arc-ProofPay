import { createPublicClient, fallback, http } from "viem";
import { arcChain } from "@/lib/chain";

const configuredRpc = arcChain.rpcUrls.default.http[0];
const fallbackRpc = arcChain.id === 5042 ? "https://rpc.mainnet.arc.io" : "https://rpc.testnet.arc.network";
const endpoints = [...new Set([configuredRpc, fallbackRpc])];

// Deliberately independent from wagmi/connectors: board reads must work before
// a wallet is connected and must not depend on an injected provider.
export const publicClient = createPublicClient({
  chain: arcChain,
  transport: fallback(endpoints.map((url) => http(url, { retryCount: 2, retryDelay: 500, timeout: 12_000 })), { rank: true }),
});
