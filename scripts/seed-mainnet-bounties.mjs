import fs from "node:fs";
import { createPublicClient, createWalletClient, getAddress, http, parseAbi, parseUnits } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { proofPayAbi } from "../lib/proofpay.ts";

const ROOT = new URL("..", import.meta.url).pathname.replace(/^\//, "").replace(/^([A-Z]):/, "$1:");
const envPath = new URL("../.env.mainnet.local", import.meta.url);
const envText = fs.readFileSync(envPath, "utf8");
const env = Object.fromEntries(envText.split(/\r?\n/).flatMap((line) => {
  const match = line.match(/^([A-Z0-9_]+)=(.*)$/);
  if (!match) return [];
  return [[match[1], match[2].replace(/^['"]|['"]$/g, "")]];
}));

const rpc = env.ARC_MAINNET_RPC_URL || "https://rpc.mainnet.arc.io";
const expectedChainId = 5042;
const proofPay = getAddress("0x1d81c9593536d814AE0976903b1df49CE8e8e401".toLowerCase());
const usdc = getAddress("0x3600000000000000000000000000000000000000");
const chain = { id: expectedChainId, name: "Arc Mainnet", nativeCurrency: { name: "USDC", symbol: "USDC", decimals: 18 }, rpcUrls: { default: { http: [rpc] } } };
const publicClient = createPublicClient({ chain, transport: http(rpc, { retryCount: 3, retryDelay: 750, timeout: 15_000 }) });
const creatorKey = env.ARC_MAINNET_CREATOR_PRIVATE_KEY;
if (!creatorKey || !/^0x[0-9a-fA-F]{64}$/.test(creatorKey)) throw new Error("ARC_MAINNET_CREATOR_PRIVATE_KEY is missing or invalid.");
const account = privateKeyToAccount(creatorKey);
const walletClient = createWalletClient({ account, chain, transport: http(rpc, { retryCount: 2, retryDelay: 750, timeout: 15_000 }) });

const taskCreatedAbi = parseAbi(["event TaskCreated(uint256 indexed taskId,address indexed creator,uint256 amount,uint64 deadline)"]);
const usdcAbi = parseAbi([
  "function decimals() view returns (uint8)",
  "function balanceOf(address) view returns (uint256)",
  "function allowance(address,address) view returns (uint256)",
  "function approve(address,uint256) returns (bool)",
]);
const targets = [
  ["Review ProofPay README", "Review the README and suggest one clear improvement."],
  ["Check mobile bounty layout", "Review the mobile bounty page and report one layout issue or confirm it looks correct."],
  ["Review smart contract comments", "Review ProofPay.sol comments and suggest one documentation improvement."],
  ["Test Arc explorer links", "Check the ProofPay Mainnet explorer links and report any broken or confusing link."],
];
const amount = parseUnits("0.01", 6);
const proofPayGas = 320000n;
const approvalGas = 90000n;
const explorer = (env.ARC_MAINNET_EXPLORER_URL || "https://explorer.arc.io").replace(/\/$/, "");

const chainId = await publicClient.getChainId();
if (chainId !== expectedChainId) throw new Error(`Unexpected chain ID: ${chainId}`);
const code = await publicClient.getBytecode({ address: proofPay });
if (!code || code === "0x") throw new Error("ProofPay bytecode is missing.");
if (await publicClient.readContract({ address: usdc, abi: usdcAbi, functionName: "decimals" }) !== 6) throw new Error("USDC decimals are not 6.");
const balance = await publicClient.readContract({ address: usdc, abi: usdcAbi, functionName: "balanceOf", args: [account.address] });
const nativeBalance = await publicClient.getBalance({ address: account.address });
console.log(`Creator: ${account.address}`);
console.log(`Balances: ${balance.toString()} raw USDC; ${nativeBalance.toString()} native wei`);

const count = Number(await publicClient.readContract({ address: proofPay, abi: proofPayAbi, functionName: "taskCount" }));
const existing = [];
for (let id = 1; id <= count; id++) {
  const task = await publicClient.readContract({ address: proofPay, abi: proofPayAbi, functionName: "getTask", args: [BigInt(id)] });
  existing.push(task);
}
const duplicateTitles = targets.filter(([title]) => existing.filter((task) => task.title === title).length > 1);
if (duplicateTitles.length) throw new Error(`Duplicate target titles already exist: ${duplicateTitles.map(([title]) => title).join(", ")}`);
const missing = targets.filter(([title]) => !existing.some((task) => task.title === title));
if (!missing.length) {
  console.log("All four requested bounties already exist; no transactions sent.");
  for (const [title] of targets) { const task = existing.find((item) => item.title === title); console.log(`OPEN_CHECK title=${title} task=${task.id} status=${task.status}`); }
  process.exit(0);
}
const total = amount * BigInt(missing.length);
if (balance < total) throw new Error(`Insufficient USDC: need ${total} raw units.`);
const gasPrice = await publicClient.getGasPrice();
let nonce = await publicClient.getTransactionCount({ address: account.address, blockTag: "pending" });
let allowance = await publicClient.readContract({ address: usdc, abi: usdcAbi, functionName: "allowance", args: [account.address, proofPay] });
if (allowance !== total) {
  const approval = await walletClient.writeContract({ address: usdc, abi: usdcAbi, functionName: "approve", args: [proofPay, total], gas: approvalGas, gasPrice, nonce: nonce++ });
  const receipt = await publicClient.waitForTransactionReceipt({ hash: approval });
  if (receipt.status !== "success") throw new Error(`Approval failed: ${approval}`);
  console.log(`Approval: ${approval}`);
}
const deadline = BigInt(Math.floor(Date.now() / 1000) + 14 * 24 * 60 * 60);
for (const [title, description] of missing) {
  const hash = await walletClient.writeContract({ address: proofPay, abi: proofPayAbi, functionName: "createTask", args: [title, description, amount, deadline], gas: proofPayGas, gasPrice, nonce: nonce++ });
  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  if (receipt.status !== "success") throw new Error(`Create failed: ${hash}`);
  const logs = receipt.logs.filter((log) => log.address.toLowerCase() === proofPay.toLowerCase());
  const parsed = await publicClient.getLogs({ address: proofPay, event: taskCreatedAbi[0], fromBlock: receipt.blockNumber, toBlock: receipt.blockNumber });
  const taskId = parsed.find((log) => log.transactionHash === hash)?.args.taskId;
  if (taskId === undefined) throw new Error(`Could not identify task ID for ${hash}`);
  const task = await publicClient.readContract({ address: proofPay, abi: proofPayAbi, functionName: "getTask", args: [taskId] });
  if (task.status !== 0 || task.amount !== amount || task.title !== title) throw new Error(`Task verification failed for ${hash}`);
  console.log(`Task ${taskId}: ${title}`);
  console.log(`Transaction: ${explorer}/tx/${hash}`);
  console.log(`Status: OPEN amount_raw=${task.amount}`);
}
console.log(`Seeded ${missing.length} requested bounties for ${Number(total) / 1e6} USDC total.`);
