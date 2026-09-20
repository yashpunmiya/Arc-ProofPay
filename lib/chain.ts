import { defineChain, getAddress } from "viem";
export const ARC_USDC = "0x3600000000000000000000000000000000000000" as const;
const environment = process.env.NEXT_PUBLIC_ARC_ENV?.trim();
const testnetRpc = process.env.NEXT_PUBLIC_ARC_TESTNET_RPC_URL?.trim() || "https://rpc.testnet.arc.network";
const mainnetRpc = process.env.NEXT_PUBLIC_ARC_MAINNET_RPC_URL?.trim() || "https://rpc.mainnet.arc.io";
const arcTestnetConfig = defineChain({ id: 5042002, name:"Arc Testnet", nativeCurrency:{name:"USDC",symbol:"USDC",decimals:18}, rpcUrls:{default:{http:[testnetRpc]}}, blockExplorers:{default:{name:"Arc Explorer",url:"https://explorer.testnet.arc.io"}}, testnet:true, pollingInterval: 12_000 });
export const arcMainnet = defineChain({ id: 5042, name:"Arc Mainnet", nativeCurrency:{name:"USDC",symbol:"USDC",decimals:18}, rpcUrls:{default:{http:[mainnetRpc]}}, blockExplorers:{default:{name:"Arc Explorer",url:"https://explorer.arc.io"}}, pollingInterval: 12_000 });
export const arcChain = environment === "mainnet" ? arcMainnet : arcTestnetConfig;
// Backwards-compatible name used by existing components; it always represents the active network.
export const arcTestnet = arcChain;
const configuredProofPay = environment === "mainnet" ? process.env.NEXT_PUBLIC_PROOFPAY_ADDRESS?.trim() : process.env.NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS?.trim();
// Normalize environment input before viem validates it. A mixed-case address
// with incorrect checksum casing is otherwise rejected before the RPC call.
export const proofPayAddress = configuredProofPay ? getAddress(configuredProofPay.toLowerCase()) : undefined;
export const explorerAddress=(a:string)=>`${arcChain.blockExplorers.default.url}/address/${a}`;
export const explorerTx=(h:string)=>`${arcChain.blockExplorers.default.url}/tx/${h}`;
