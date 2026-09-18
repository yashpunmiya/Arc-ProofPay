// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ProofPay} from "../src/ProofPay.sol";

contract DeployProofPay is Script {
    function run(address usdc) external returns (ProofPay deployed) {
        require(usdc != address(0), "USDC required");
        vm.startBroadcast();
        deployed = new ProofPay(usdc);
        vm.stopBroadcast();
    }
}
