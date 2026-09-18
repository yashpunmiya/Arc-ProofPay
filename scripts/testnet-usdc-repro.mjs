import fs from "node:fs";
import { createPublicClient, createWalletClient, http, parseAbi, getAddress } from "viem";
import { privateKeyToAccount } from "viem/accounts";

const env = Object.fromEntries(fs.readFileSync(".env.local", "utf8").split(/\r?\n/).filter((line) => line && !line.startsWith("#")).map((line) => {
  const i = line.indexOf("=");
  return [line.slice(0, i), line.slice(i + 1).replace(/^['\"]|['\"]$/g, "")];
}));
const rpc = env.ARC_TESTNET_RPC_URL;
const token = getAddress("0x3600000000000000000000000000000000000000");
let proofPay = getAddress(env.NEXT_PUBLIC_PROOFPAY_TESTNET_ADDRESS);
const creator = privateKeyToAccount(env.ARC_TESTNET_CREATOR_PRIVATE_KEY);
const worker = privateKeyToAccount(env.ARC_TESTNET_WORKER_PRIVATE_KEY);
const abi = parseAbi(["function approve(address,uint256) returns (bool)", "function transferFrom(address,address,uint256) returns (bool)", "function balanceOf(address) view returns (uint256)", "function createTask(string,string,uint256,uint64) returns (uint256)", "function taskCount() view returns (uint256)", "function claimTask(uint256)", "function submitProof(uint256,string)", "function approveAndPay(uint256)"]);
const transport = http(rpc);
const publicClient = createPublicClient({ transport });
const creatorWallet = createWalletClient({ account: creator, transport });
const workerWallet = createWalletClient({ account: worker, transport });
const amount = 1n;
console.log(`creator=${creator.address}`);
console.log(`worker=${worker.address}`);
console.log(`proofPay=${proofPay}`);
if (process.env.REDEPLOY_CURRENT_BUILD === "1") {
  const artifact = JSON.parse(fs.readFileSync("contracts/out/ProofPay.sol/ProofPay.json", "utf8"));
  const deployment = await creatorWallet.deployContract({ abi: artifact.abi, bytecode: artifact.bytecode.object, args: [token], chain: null });
  console.log(`redeploy_tx=${deployment}`);
  const receipt = await publicClient.waitForTransactionReceipt({ hash: deployment });
  proofPay = getAddress(receipt.contractAddress);
  console.log(`redeployed_proofPay=${proofPay}`);
}
const approval = await creatorWallet.writeContract({ address: token, abi, functionName: "approve", args: [worker.address, amount], chain: null });
console.log(`approve_worker_tx=${approval}`);
await publicClient.waitForTransactionReceipt({ hash: approval });
try {
  const transfer = await workerWallet.writeContract({ address: token, abi, functionName: "transferFrom", args: [creator.address, worker.address, amount], chain: null });
  console.log(`direct_transferFrom_tx=${transfer}`);
  await publicClient.waitForTransactionReceipt({ hash: transfer });
} catch (error) {
  console.log(`direct_transferFrom_error=${error.shortMessage ?? error.message}`);
}
const proofPayApproval = await creatorWallet.writeContract({ address: token, abi, functionName: "approve", args: [proofPay, amount], chain: null });
console.log(`approve_proofPay_tx=${proofPayApproval}`);
await publicClient.waitForTransactionReceipt({ hash: proofPayApproval });
const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600);
try {
  const create = await creatorWallet.writeContract({ address: proofPay, abi, functionName: "createTask", args: ["repro", "direct transferFrom comparison", amount, deadline], chain: null });
  console.log(`proofpay_create_tx=${create}`);
  const receipt = await publicClient.waitForTransactionReceipt({ hash: create });
  console.log(`proofpay_create_status=${receipt.status}`);
  const taskId = await publicClient.readContract({ address: proofPay, abi, functionName: "taskCount" });
  const claim = await workerWallet.writeContract({ address: proofPay, abi, functionName: "claimTask", args: [taskId], chain: null });
  await publicClient.waitForTransactionReceipt({ hash: claim });
  const submit = await workerWallet.writeContract({ address: proofPay, abi, functionName: "submitProof", args: [taskId, "https://example.invalid/repro"], chain: null });
  await publicClient.waitForTransactionReceipt({ hash: submit });
  const before = await publicClient.readContract({ address: token, abi, functionName: "balanceOf", args: [worker.address] });
  const pay = await creatorWallet.writeContract({ address: proofPay, abi, functionName: "approveAndPay", args: [taskId], chain: null });
  await publicClient.waitForTransactionReceipt({ hash: pay });
  const after = await publicClient.readContract({ address: token, abi, functionName: "balanceOf", args: [worker.address] });
  console.log(`full_lifecycle_task=${taskId} payout_raw=${after - before} approveAndPay_tx=${pay}`);
} catch (error) {
  console.log(`proofpay_create_error=${error.shortMessage ?? error.message}`);
}
