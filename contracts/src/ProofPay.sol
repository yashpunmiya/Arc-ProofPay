// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Fixed-USDC escrow for creator-controlled outcome bounties. No arbitration is provided.
contract ProofPay is ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint256 public constant MAX_TITLE_BYTES = 120;
    uint256 public constant MAX_DESCRIPTION_BYTES = 1500;
    uint256 public constant MAX_PROOF_URI_BYTES = 500;
    uint64 public constant MIN_DEADLINE_DELAY = 10 minutes;
    uint64 public constant MAX_DEADLINE_DELAY = 90 days;
    IERC20 public immutable usdc;
    uint256 public taskCount;
    enum Status {
        OPEN,
        CLAIMED,
        SUBMITTED,
        COMPLETED,
        CANCELLED,
        REFUNDED,
        REJECTED
    }

    struct Task {
        uint256 id;
        address creator;
        address worker;
        uint256 amount;
        uint64 deadline;
        uint64 createdAt;
        uint64 claimedAt;
        uint64 submittedAt;
        Status status;
        string title;
        string description;
        string proofURI;
    }
    mapping(uint256 => Task) private _tasks;
    error TaskNotFound();
    error InvalidAmount();
    error InvalidDeadline();
    error TitleRequired();
    error TitleTooLong();
    error DescriptionTooLong();
    error ProofRequired();
    error ProofTooLong();
    error ReasonRequired();
    error ReasonTooLong();
    error Unauthorized();
    error InvalidStatus();
    error DeadlinePassed();
    error DeadlineNotPassed();
    error CreatorCannotClaim();
    error InvalidToken();
    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 amount, uint64 deadline);
    event TaskClaimed(uint256 indexed taskId, address indexed worker);
    event TaskClaimReleased(uint256 indexed taskId, address indexed worker);
    event ProofSubmitted(uint256 indexed taskId, address indexed worker);
    event TaskCompleted(uint256 indexed taskId, address indexed worker, uint256 amount);
    event TaskRejected(uint256 indexed taskId, address indexed creator);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);
    event TaskRefunded(uint256 indexed taskId, address indexed creator);

    constructor(address token) {
        if (token == address(0)) revert InvalidToken();
        // ProofPay stores raw ERC-20 units and is intentionally fixed to USDC's
        // six-decimal interface. Reject a wrongly configured token at deployment.
        if (IERC20Metadata(token).decimals() != 6) revert InvalidToken();
        usdc = IERC20(token);
    }

    function getTask(uint256 taskId) external view returns (Task memory) {
        return _task(taskId);
    }

    function createTask(string calldata title, string calldata description, uint256 amount, uint64 deadline)
        external
        nonReentrant
        returns (uint256 id)
    {
        _validateCreate(title, description, amount, deadline);
        id = ++taskCount;
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        _tasks[id] = Task(
            id,
            msg.sender,
            address(0),
            amount,
            deadline,
            uint64(block.timestamp),
            0,
            0,
            Status.OPEN,
            title,
            description,
            ""
        );
        emit TaskCreated(id, msg.sender, amount, deadline);
    }

    function claimTask(uint256 taskId) external {
        Task storage t = _tasks[taskId];
        _requireExists(t);
        if (t.status != Status.OPEN) revert InvalidStatus();
        if (block.timestamp >= t.deadline) revert DeadlinePassed();
        if (msg.sender == t.creator) revert CreatorCannotClaim();
        t.worker = msg.sender;
        t.claimedAt = uint64(block.timestamp);
        t.status = Status.CLAIMED;
        emit TaskClaimed(taskId, msg.sender);
    }

    function releaseClaim(uint256 taskId) external {
        Task storage t = _tasks[taskId];
        _requireExists(t);
        if (t.status != Status.CLAIMED) revert InvalidStatus();
        if (msg.sender != t.worker) revert Unauthorized();
        if (block.timestamp >= t.deadline) revert DeadlinePassed();
        t.worker = address(0);
        t.claimedAt = 0;
        t.status = Status.OPEN;
        emit TaskClaimReleased(taskId, msg.sender);
    }

    function submitProof(uint256 taskId, string calldata proofURI) external {
        Task storage t = _tasks[taskId];
        _requireExists(t);
        if (t.status != Status.CLAIMED) revert InvalidStatus();
        if (msg.sender != t.worker) revert Unauthorized();
        if (block.timestamp >= t.deadline) revert DeadlinePassed();
        if (bytes(proofURI).length == 0) revert ProofRequired();
        if (bytes(proofURI).length > MAX_PROOF_URI_BYTES) revert ProofTooLong();
        t.proofURI = proofURI;
        t.submittedAt = uint64(block.timestamp);
        t.status = Status.SUBMITTED;
        emit ProofSubmitted(taskId, msg.sender);
    }

    function approveAndPay(uint256 taskId) external nonReentrant {
        Task storage t = _tasks[taskId];
        _requireExists(t);
        if (msg.sender != t.creator) revert Unauthorized();
        if (t.status != Status.SUBMITTED) revert InvalidStatus();
        t.status = Status.COMPLETED;
        usdc.safeTransfer(t.worker, t.amount);
        emit TaskCompleted(taskId, t.worker, t.amount);
    }

    function rejectAndRefund(uint256 taskId, string calldata reason) external nonReentrant {
        Task storage t = _tasks[taskId];
        _requireExists(t);
        if (msg.sender != t.creator) revert Unauthorized();
        if (t.status != Status.SUBMITTED) revert InvalidStatus();
        if (bytes(reason).length == 0) revert ReasonRequired();
        if (bytes(reason).length > 300) revert ReasonTooLong();
        t.status = Status.REJECTED;
        usdc.safeTransfer(t.creator, t.amount);
        emit TaskRejected(taskId, msg.sender);
    }

    function cancelTask(uint256 taskId) external nonReentrant {
        Task storage t = _tasks[taskId];
        _requireExists(t);
        if (msg.sender != t.creator) revert Unauthorized();
        if (t.status != Status.OPEN) revert InvalidStatus();
        t.status = Status.CANCELLED;
        usdc.safeTransfer(t.creator, t.amount);
        emit TaskCancelled(taskId, msg.sender);
    }

    function refundExpiredTask(uint256 taskId) external nonReentrant {
        Task storage t = _tasks[taskId];
        _requireExists(t);
        if (block.timestamp < t.deadline) revert DeadlineNotPassed();
        if (t.status != Status.OPEN && t.status != Status.CLAIMED) revert InvalidStatus();
        t.status = Status.REFUNDED;
        usdc.safeTransfer(t.creator, t.amount);
        emit TaskRefunded(taskId, t.creator);
    }

    function _task(uint256 id) internal view returns (Task storage t) {
        t = _tasks[id];
        _requireExists(t);
    }

    function _requireExists(Task storage t) internal view {
        if (t.id == 0) revert TaskNotFound();
    }

    function _validateCreate(string calldata title, string calldata description, uint256 amount, uint64 deadline)
        internal
        view
    {
        if (amount == 0) revert InvalidAmount();
        if (bytes(title).length == 0) revert TitleRequired();
        if (bytes(title).length > MAX_TITLE_BYTES) revert TitleTooLong();
        if (bytes(description).length > MAX_DESCRIPTION_BYTES) revert DescriptionTooLong();
        if (deadline < block.timestamp + MIN_DEADLINE_DELAY || deadline > block.timestamp + MAX_DEADLINE_DELAY) {
            revert InvalidDeadline();
        }
    }
}
