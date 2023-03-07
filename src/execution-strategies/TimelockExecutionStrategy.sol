// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SimpleQuorumExecutionStrategy } from "./SimpleQuorumExecutionStrategy.sol";
import { SpaceManager } from "../utils/SpaceManager.sol";
import { MetaTransaction, Proposal, ProposalStatus } from "../types.sol";
import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/// @title Timelock Execution Strategy - An Execution strategy that executes transactions according to a timelock delay.
contract TimelockExecutionStrategy is SpaceManager, SimpleQuorumExecutionStrategy {
    /// @notice Returned if timelock delay is in the future.
    error TimelockDelayNotMet();
    /// @notice Returned if the proposal execution payload hash is not queued.
    error ProposalNotQueued();
    /// @notice Returned if the proposal execution payload hash is already queued.
    error DuplicateExecutionPayloadHash();

    event TransactionQueued(MetaTransaction transaction, uint256 executionTime);
    event TransactionExecuted(MetaTransaction transaction);

    /// @notice The delay in seconds between a proposal being queued and the execution of the proposal.
    uint256 public immutable TIMELOCK_DELAY;

    /// @notice The time at which a proposal can be executed. Indexed by the hash of the proposal execution payload.
    mapping(bytes32 => uint256) public proposalExecutionTime;

    /// @notice Constructor
    /// @param _owner Address of the owner of this contract.
    /// @param _spaces Array of whitelisted space contracts.
    /// @param _timelockDelay The timelock delay in seconds.
    constructor(address _owner, address[] memory _spaces, uint256 _timelockDelay) initializer {
        __Ownable_init();
        transferOwnership(_owner);
        __SpaceManager_init(_spaces);
        TIMELOCK_DELAY = _timelockDelay;
    }

    /// @notice Effectively a timelock queue function. Can only be called by approved spaces.
    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external override onlySpace(msg.sender) {
        if (proposal.executionPayloadHash != keccak256(payload)) revert InvalidPayload();

        ProposalStatus proposalStatus = getProposalStatus(proposal, votesFor, votesAgainst, votesAbstain);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }

        if (proposalExecutionTime[proposal.executionPayloadHash] != 0) revert DuplicateExecutionPayloadHash();

        uint256 executionTime = block.timestamp + TIMELOCK_DELAY;
        proposalExecutionTime[proposal.executionPayloadHash] = executionTime;

        MetaTransaction[] memory transactions = abi.decode(payload, (MetaTransaction[]));
        for (uint i = 0; i < transactions.length; i++) {
            emit TransactionQueued(transactions[i], executionTime);
        }
    }

    /// @notice Executes a queued proposal. Can be called by anyone with the execution payload.
    function execute(bytes memory payload) external {
        bytes32 executionPayloadHash = keccak256(payload);

        uint256 executionTime = proposalExecutionTime[executionPayloadHash];

        if (executionTime == 0) revert ProposalNotQueued();
        if (proposalExecutionTime[executionPayloadHash] > block.timestamp) revert TimelockDelayNotMet();

        // Reset the execution time to 0 to prevent reentrancy
        proposalExecutionTime[executionPayloadHash] = 0;

        MetaTransaction[] memory transactions = abi.decode(payload, (MetaTransaction[]));
        for (uint i = 0; i < transactions.length; i++) {
            bool success;
            if (transactions[i].operation == Enum.Operation.DelegateCall) {
                (success, ) = transactions[i].to.delegatecall(transactions[i].data);
            } else {
                (success, ) = transactions[i].to.call{ value: transactions[i].value }(transactions[i].data);
            }
            if (!success) revert TransactionsFailed();

            emit TransactionExecuted(transactions[i]);
        }
    }

    function getStrategyType() external pure override returns (string memory) {
        return "SimpleQuorumTimelock";
    }
}
