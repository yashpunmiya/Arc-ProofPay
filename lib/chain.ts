import { defineChain } from "viem";
export const ARC_USDC = "0x3600000000000000000000000000000000000000" as const;
const arcTestnetConfig = defineChain({ id: 5042002, name:"Arc Testnet", nativeCurrency:{name:"USDC",symbol:"USDC",decimals:18}, rpcUrls:{default:{http:[process.env.NEXT_PUBLIC_ARC_TESTNET_RPC_URL || "https://rpc.testnet.arc.network"]}}, blockExplorers:{default:{name:"Arc Explorer",url:"https://explorer.testnet.arc.io"}}, testnet:true, pollingInterval: 12_000 });
export const arcMainnet = defineChain({ id: 5042, name:"Arc Mainnet", nativeCurrency:{name:"USDC",symbol:"USDC",decimals:18}, rpcUrls:{default:{http:[process.env.NEXT_PUBLIC_ARC_MAINNET_RPC_URL || "https://rpc.mainnet.arc.io"]}}, blockExplorers:{default:{name:"Arc Explorer",url:"https://explorer.arc.io"}}, pollingInterval: 12_000 });
export const arcChain = process.env.NEXT_PUBLIC_ARC_ENV === "mainnet" ? arcMainnet : arcTestnetConfig;
// Backwards-compatible name used by existing components; it always represents the active network.
export const arcTestnet = arcChain;
export const proofPayAddress = (process.env.NEXT_PUBLIC_ARC_ENV === "mainnet" ? process.env.NEXT_PUBLIC_PROOFPAY_ADDRESS : process.env.NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS) as `0x${string}` | undefined;
export const explorerAddress=(a:string)=>`${arcChain.blockExplorers.default.url}/address/${a}`;
export const explorerTx=(h:string)=>`${arcChain.blockExplorers.default.url}/tx/${h}`;
