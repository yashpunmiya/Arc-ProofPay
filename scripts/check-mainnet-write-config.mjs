import { createPublicClient, http, getAddress } from "viem";
import { PROOFPAY_GAS_LIMITS, buildProofPayWrite, encodeProofPayWrite } from "../lib/transaction-config.ts";

const expectedProofPay = getAddress("0x1d81c9593536d814ae0976903b1df49CE8e8e401");
const expectedUsdc = getAddress("0x3600000000000000000000000000000000000000");
const rpc = process.env.NEXT_PUBLIC_ARC_MAINNET_RPC_URL || "https://rpc.mainnet.arc.io";
const client = createPublicClient({ transport: http(rpc) });
const chainId = await client.getChainId();
if (chainId !== 5042) throw new Error(`wrong chain: ${chainId}`);
const code = await client.getBytecode({ address: expectedProofPay });
const usdcCode = await client.getBytecode({ address: expectedUsdc });
if (!code || code === "0x" || !usdcCode || usdcCode === "0x") throw new Error("missing Mainnet bytecode");
const decimals = await client.readContract({ address: expectedUsdc, abi: [{ type: "function", name: "decimals", stateMutability: "view", inputs: [], outputs: [{ type: "uint8" }] }], functionName: "decimals" });
if (decimals !== 6) throw new Error(`wrong USDC decimals: ${decimals}`);
const examples = [
  ["claimTask", [1n]], ["releaseClaim", [1n]], ["approveAndPay", [1n]], ["cancelTask", [1n]], ["refundExpiredTask", [1n]],
  ["submitProof", [1n, "https://example.invalid/proof"]], ["rejectAndRefund", [1n, "not accepted"]],
  ["createTask", ["example", "read-only calldata check", 1n, BigInt(Math.floor(Date.now() / 1000) + 3600)]],
];
for (const [functionName, args] of examples) {
  const request = buildProofPayWrite(expectedProofPay, { functionName, args });
  const data = encodeProofPayWrite({ functionName, args });
  if (!data.startsWith("0x") || request.gas !== PROOFPAY_GAS_LIMITS[functionName]) throw new Error(`invalid ${functionName} request`);
}
console.log(`mainnet_write_config=PASS chain_id=${chainId} proofpay=${expectedProofPay} usdc=${expectedUsdc} decimals=${decimals} writes=${examples.length}`);
