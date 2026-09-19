// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ProofPay} from "../src/ProofPay.sol";

/// @notice Deliberately separate, manually invoked smoke lifecycle for Arc Mainnet.
contract MainnetSmoke is Script {
    function run(address proofPayAddress, address usdcAddress, uint256 amount) external {
        require(amount > 0, "amount required");
        uint256 creatorKey = vm.envUint("ARC_MAINNET_CREATOR_PRIVATE_KEY");
        uint256 workerKey = vm.envUint("ARC_MAINNET_WORKER_PRIVATE_KEY");
        address creator = vm.addr(creatorKey);
        address worker = vm.addr(workerKey);
        ProofPay proofPay = ProofPay(proofPayAddress);
        IERC20 usdc = IERC20(usdcAddress);
        require(address(proofPay.usdc()) == usdcAddress, "wrong USDC");

        uint256 beforeBalance = usdc.balanceOf(worker);
        vm.startBroadcast(creatorKey);
        if (usdc.allowance(creator, proofPayAddress) < amount) {
            usdc.approve(proofPayAddress, amount);
        }
        uint256 taskId = proofPay.createTask(
            "Arc Mainnet smoke", "ProofPay live lifecycle", amount, uint64(block.timestamp + 1 hours)
        );
        vm.stopBroadcast();

        vm.startBroadcast(workerKey);
        proofPay.claimTask(taskId);
        proofPay.submitProof(taskId, "https://example.com/proofpay-mainnet-smoke");
        vm.stopBroadcast();

        vm.startBroadcast(creatorKey);
        proofPay.approveAndPay(taskId);
        vm.stopBroadcast();

        require(uint8(proofPay.getTask(taskId).status) == uint8(ProofPay.Status.COMPLETED), "task not completed");
        require(usdc.balanceOf(worker) == beforeBalance + amount, "worker payout mismatch");
        require(usdc.balanceOf(proofPayAddress) == 0, "escrow not released");
        console2.log("Smoke task ID", taskId);
        console2.log("Creator", creator);
        console2.log("Worker", worker);
        console2.log("Amount (raw USDC units)", amount);
    }
}
