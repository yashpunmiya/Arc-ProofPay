// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ProofPay} from "../src/ProofPay.sol";

contract TestnetSmoke is Script {
    uint256 internal constant AMOUNT = 1_000_000;

    function run(address proofPayAddress, address usdcAddress) external {
        uint256 creatorKey = vm.envUint("ARC_TESTNET_CREATOR_PRIVATE_KEY");
        uint256 workerKey = vm.envUint("ARC_TESTNET_WORKER_PRIVATE_KEY");
        address creator = vm.addr(creatorKey);
        address worker = vm.addr(workerKey);
        ProofPay proofPay = ProofPay(proofPayAddress);
        IERC20 usdc = IERC20(usdcAddress);

        vm.startBroadcast(creatorKey);
        usdc.approve(proofPayAddress, AMOUNT);
        uint256 taskId = proofPay.createTask(
            "Arc Testnet smoke", "ProofPay live lifecycle", AMOUNT, uint64(block.timestamp + 1 hours)
        );
        vm.stopBroadcast();

        vm.startBroadcast(workerKey);
        proofPay.claimTask(taskId);
        proofPay.submitProof(taskId, "https://example.com/proofpay-smoke");
        vm.stopBroadcast();

        uint256 beforeBalance = usdc.balanceOf(worker);
        vm.startBroadcast(creatorKey);
        proofPay.approveAndPay(taskId);
        vm.stopBroadcast();

        require(uint8(proofPay.getTask(taskId).status) == uint8(ProofPay.Status.COMPLETED), "task not completed");
        require(usdc.balanceOf(worker) == beforeBalance + AMOUNT, "worker payout mismatch");
        require(usdc.balanceOf(proofPayAddress) == 0, "escrow not released");
        console2.log("Smoke task ID", taskId);
        console2.log("Creator", creator);
        console2.log("Worker", worker);
    }
}
