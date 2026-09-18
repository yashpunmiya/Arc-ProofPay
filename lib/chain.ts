import { defineChain } from "viem";
export const ARC_USDC = "0x3600000000000000000000000000000000000000" as const;
export const arcTestnet = defineChain({ id: 5042002, name:"Arc Testnet", nativeCurrency:{name:"USDC",symbol:"USDC",decimals:18}, rpcUrls:{default:{http:[process.env.NEXT_PUBLIC_ARC_TESTNET_RPC_URL || "https://rpc.testnet.arc.network"]}}, blockExplorers:{default:{name:"Arc Explorer",url:"https://explorer.testnet.arc.io"}}, testnet:true, pollingInterval: 12_000 });
export const proofPayAddress = process.env.NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS as `0x${string}` | undefined;
export const explorerAddress=(a:string)=>`${arcTestnet.blockExplorers.default.url}/address/${a}`;
export const explorerTx=(h:string)=>`${arcTestnet.blockExplorers.default.url}/tx/${h}`;
