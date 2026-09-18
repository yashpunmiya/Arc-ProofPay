// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ProofPay} from "../src/ProofPay.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

contract LocalLifecycle is Script {
    uint256 internal constant CREATOR_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 internal constant WORKER_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    function run() external {
        address creator = vm.addr(CREATOR_KEY);
        address worker = vm.addr(WORKER_KEY);
        vm.startBroadcast(CREATOR_KEY);
        MockUSDC token = new MockUSDC();
        ProofPay proofPay = new ProofPay(address(token));
        token.mint(creator, 10_000_000);
        token.approve(address(proofPay), 1_000_000);
        uint256 taskId =
            proofPay.createTask("Local lifecycle", "Anvil verification", 1_000_000, uint64(block.timestamp + 1 days));
        vm.stopBroadcast();

        vm.startBroadcast(WORKER_KEY);
        proofPay.claimTask(taskId);
        proofPay.submitProof(taskId, "https://example.com/proof");
        vm.stopBroadcast();

        vm.startBroadcast(CREATOR_KEY);
        proofPay.approveAndPay(taskId);
        vm.stopBroadcast();
        require(uint8(proofPay.getTask(taskId).status) == uint8(ProofPay.Status.COMPLETED), "lifecycle failed");
        require(token.balanceOf(worker) == 1_000_000, "payout failed");
    }
}
