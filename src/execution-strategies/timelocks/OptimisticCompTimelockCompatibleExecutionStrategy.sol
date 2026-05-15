// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ICompTimelock } from "../../interfaces/ICompTimelock.sol";
import { OptimisticQuorumExecutionStrategy } from "../OptimisticQuorumExecutionStrategy.sol";
import { SpaceManager } from "../../utils/SpaceManager.sol";
import { MetaTransaction, Proposal, ProposalStatus } from "../../types.sol";
import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/// @title Optimistic Comp Timelock Execution Strategy
/// @notice An optimstic execution strategy that provides compatibility with existing Comp Timelock contracts.
contract OptimisticCompTimelockCompatibleExecutionStrategy is OptimisticQuorumExecutionStrategy {
    /// @notice Thrown if timelock delay is in the future.
    error TimelockDelayNotMet();
    /// @notice Thrown if the proposal execution payload hash is not queued.
    error ProposalNotQueued();
    /// @notice Thrown if the proposal execution payload hash is already queued.
    error DuplicateExecutionPayloadHash();
    /// @notice Thrown if the same MetaTransaction appears twice in the same payload (salt is not taken into account).
    error DuplicateMetaTransaction();
    /// @notice Thrown if veto caller is not the veto guardian.
    error OnlyVetoGuardian();
    /// @notice Thrown if the transaction is invalid.
    error InvalidTransaction();

    event OptimisticCompTimelockCompatibleExecutionStrategySetUp(
        address owner,
        address vetoGuardian,
        address[] spaces,
        uint256 quorum,
        address timelock
    );
    event TransactionQueued(MetaTransaction transaction, uint256 executionTime);
    event TransactionExecuted(MetaTransaction transaction);
    event TransactionVetoed(MetaTransaction transaction);
    event VetoGuardianSet(address vetoGuardian, address newVetoGuardian);
    event ProposalVetoed(bytes32 executionPayloadHash);
    event ProposalQueued(bytes32 executionPayloadHash);
    event ProposalExecuted(bytes32 executionPayloadHash);

    /// @notice The time at which a proposal can be executed. Indexed by the hash of the proposal execution payload.
    mapping(bytes32 => uint256) public proposalExecutionTime;

    /// @notice Veto guardian is given permission to veto any queued proposal.
    address public vetoGuardian;

    /// @notice The timelock contract.
    ICompTimelock public timelock;

    /// @notice Constructor
    constructor(address _owner, address _vetoGuardian, address[] memory _spaces, uint256 _quorum, address _timelock) {
        setUp(abi.encode(_owner, _vetoGuardian, _spaces, _quorum, _timelock));
    }

    function setUp(bytes memory initializeParams) public initializer {
        (address _owner, address _vetoGuardian, address[] memory _spaces, uint256 _quorum, address _timelock) = abi
            .decode(initializeParams, (address, address, address[], uint256, address));
        __Ownable_init(_owner);
        vetoGuardian = _vetoGuardian;
        __SpaceManager_init(_spaces);
        __OptimisticQuorumExecutionStrategy_init(_quorum);
        timelock = ICompTimelock(_timelock);
        emit OptimisticCompTimelockCompatibleExecutionStrategySetUp(_owner, _vetoGuardian, _spaces, _quorum, _timelock);
    }

    /// @notice Accepts admin role of the timelock contract. Must be called before using the timelock.
    function acceptAdmin() external {
        timelock.acceptAdmin();
    }

    /// @notice The delay in seconds between a proposal being queued and the execution of the proposal.
    function timelockDelay() public view returns (uint256) {
        return timelock.delay();
    }

    /// @notice Executes a proposal by queueing its transactions in the timelock. Can only be called by approved spaces.
    function execute(
        uint256 /* proposalId */,
        Proposal memory proposal,
        bool quorumReached,
        bool supportAchieved,
        bytes memory payload
    ) external override onlySpace {
        ProposalStatus proposalStatus = getProposalStatus(proposal, quorumReached, supportAchieved);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }

        if (proposalExecutionTime[proposal.executionPayloadHash] != 0) revert DuplicateExecutionPayloadHash();

        uint256 executionTime = block.timestamp + timelockDelay();
        proposalExecutionTime[proposal.executionPayloadHash] = executionTime;

        MetaTransaction[] memory transactions = abi.decode(payload, (MetaTransaction[]));

        for (uint256 i = 0; i < transactions.length; i++) {
            // Comp Timelock does not support delegate calls.
            if (transactions[i].operation == Enum.Operation.DelegateCall) {
                revert InvalidTransaction();
            }

            bytes32 txHash = keccak256(
                abi.encode(transactions[i].to, transactions[i].value, "", transactions[i].data, executionTime)
            );
            if (timelock.queuedTransactions(txHash) != false) revert DuplicateMetaTransaction();

            timelock.queueTransaction(
                transactions[i].to,
                transactions[i].value,
                "",
                transactions[i].data,
                executionTime
            );
            emit TransactionQueued(transactions[i], executionTime);
        }
        emit ProposalQueued(proposal.executionPayloadHash);
    }

    /// @notice Executes a queued proposal.
    function executeQueuedProposal(bytes memory payload) external {
        bytes32 executionPayloadHash = keccak256(payload);

        uint256 executionTime = proposalExecutionTime[executionPayloadHash];

        if (executionTime == 0) revert ProposalNotQueued();
        if (proposalExecutionTime[executionPayloadHash] > block.timestamp) revert TimelockDelayNotMet();

        // Reset the execution time to 0 to prevent reentrancy.
        proposalExecutionTime[executionPayloadHash] = 0;

        MetaTransaction[] memory transactions = abi.decode(payload, (MetaTransaction[]));
        for (uint256 i = 0; i < transactions.length; i++) {
            timelock.executeTransaction(
                transactions[i].to,
                transactions[i].value,
                "",
                transactions[i].data,
                executionTime
            );
            emit TransactionExecuted(transactions[i]);
        }
        emit ProposalExecuted(executionPayloadHash);
    }

    /// @notice Vetoes a queued proposal.
    function veto(bytes memory payload) external {
        bytes32 payloadHash = keccak256(payload);
        if (msg.sender != vetoGuardian) revert OnlyVetoGuardian();

        uint256 executionTime = proposalExecutionTime[payloadHash];
        if (executionTime == 0) revert ProposalNotQueued();

        MetaTransaction[] memory transactions = abi.decode(payload, (MetaTransaction[]));
        for (uint256 i = 0; i < transactions.length; i++) {
            timelock.cancelTransaction(
                transactions[i].to,
                transactions[i].value,
                "",
                transactions[i].data,
                executionTime
            );
            emit TransactionVetoed(transactions[i]);
        }
        proposalExecutionTime[payloadHash] = 0;
        emit ProposalVetoed(payloadHash);
    }

    /// @notice Sets the veto guardian.
    function setVetoGuardian(address newVetoGuardian) external onlyOwner {
        emit VetoGuardianSet(vetoGuardian, newVetoGuardian);
        vetoGuardian = newVetoGuardian;
    }

    /// @notice Returns the strategy type string.
    function getStrategyType() external pure override returns (string memory) {
        return "CompTimelockCompatibleOptimisticQuorum";
    }
}
