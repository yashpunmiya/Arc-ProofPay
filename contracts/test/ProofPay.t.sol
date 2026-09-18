// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test} from "forge-std/Test.sol";
import {ProofPay} from "../src/ProofPay.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WrongDecimalsToken is ERC20 {
    constructor() ERC20("Wrong decimals", "WRONG") {}
}

contract ProofPayTest is Test {
    ProofPay p;
    MockUSDC u;
    address creator = makeAddr("creator");
    address worker = makeAddr("worker");
    address other = makeAddr("other");
    uint256 constant AMOUNT = 5_000_000;

    function setUp() public {
        u = new MockUSDC();
        p = new ProofPay(address(u));
        u.mint(creator, 100_000_000);
        vm.prank(creator);
        u.approve(address(p), type(uint256).max);
    }

    function create() internal returns (uint256) {
        vm.prank(creator);
        return p.createTask("Fix CSS", "Small mobile fix", AMOUNT, uint64(block.timestamp + 11 minutes));
    }

    function testCreateEscrows() public {
        uint256 id = create();
        assertEq(p.taskCount(), 1);
        assertEq(u.balanceOf(address(p)), AMOUNT);
        assertEq(p.getTask(id).creator, creator);
    }

    function testRejectsNonSixDecimalToken() public {
        WrongDecimalsToken wrong = new WrongDecimalsToken();
        vm.expectRevert(ProofPay.InvalidToken.selector);
        new ProofPay(address(wrong));
    }

    function testClaimSubmitApprovePaysExact() public {
        uint256 id = create();
        vm.prank(worker);
        p.claimTask(id);
        vm.prank(worker);
        p.submitProof(id, "https://example.com/pr");
        uint256 before = u.balanceOf(worker);
        vm.prank(creator);
        p.approveAndPay(id);
        assertEq(u.balanceOf(worker), before + AMOUNT);
        assertEq(uint8(p.getTask(id).status), 3);
        assertEq(u.balanceOf(address(p)), 0);
    }

    function testCreatorCannotClaim() public {
        uint256 id = create();
        vm.prank(creator);
        vm.expectRevert(ProofPay.CreatorCannotClaim.selector);
        p.claimTask(id);
    }

    function testCancelReturnsFunds() public {
        uint256 id = create();
        uint256 before = u.balanceOf(creator);
        vm.prank(creator);
        p.cancelTask(id);
        assertEq(u.balanceOf(creator), before + AMOUNT);
        assertEq(uint8(p.getTask(id).status), 4);
    }

    function testExpiredClaimRefunds() public {
        uint256 id = create();
        vm.prank(worker);
        p.claimTask(id);
        vm.warp(block.timestamp + 12 minutes);
        p.refundExpiredTask(id);
        assertEq(uint8(p.getTask(id).status), 5);
        assertEq(u.balanceOf(address(p)), 0);
    }

    function testSubmittedCannotRefund() public {
        uint256 id = create();
        vm.prank(worker);
        p.claimTask(id);
        vm.prank(worker);
        p.submitProof(id, "https://proof");
        vm.warp(block.timestamp + 12 minutes);
        vm.expectRevert(ProofPay.InvalidStatus.selector);
        p.refundExpiredTask(id);
    }

    function testFuzzAmounts(uint96 raw) public {
        uint256 a = bound(uint256(raw), 1, 100_000_000);
        vm.prank(creator);
        p.createTask("x", "", a, uint64(block.timestamp + 11 minutes));
        assertEq(u.balanceOf(address(p)), a);
    }
}
