// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SimpleQuorumExecutionStrategy } from "./SimpleQuorumExecutionStrategy.sol";
import { SpaceManager } from "../utils/SpaceManager.sol";
import { MetaTransaction, Proposal, ProposalStatus } from "../types.sol";

/// @title Avatar Execution Strategy - An Execution strategy that executes transactions on an Avatar contract
/// @dev An Avatar contract is any contract that implements the IAvatar interface, eg a Gnosis Safe.
contract TimelockExecutionStrategy is SpaceManager, SimpleQuorumExecutionStrategy {
    error TransactionsFailed();
    error TimelockDelayNotMet();
    error ProposalNotQueued();

    /// @notice The delay in seconds between a proposal being queued and the execution of the proposal.
    uint256 public timelockDelay;

    /// @notice The time at which a proposal can be executed. Indexed by the hash of the proposal execution payload.
    mapping(bytes32 => uint256) public proposalExecutionTime;

    /// @notice Constructor
    /// @param _owner Address of the owner of this contract.
    /// @param _spaces Array of whitelisted space contracts.
    constructor(address _owner, address[] memory _spaces, uint256 _timelockDelay) {
        __Ownable_init();
        transferOwnership(_owner);
        __SpaceManager_init(_spaces);
        timelockDelay = _timelockDelay;
    }

    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory
    ) external override onlySpace(msg.sender) {
        ProposalStatus proposalStatus = getProposalStatus(proposal, votesFor, votesAgainst, votesAbstain);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }

        proposalExecutionTime[proposal.executionPayloadHash] = block.timestamp + timelockDelay;
    }

    function execute(Proposal memory proposal, bytes memory payload) external {
        // Check that the execution payload matches the payload supplied when the proposal was created
        if (proposal.executionPayloadHash != keccak256(payload)) revert InvalidPayload();

        uint256 executionTime = proposalExecutionTime[proposal.executionPayloadHash];

        if (executionTime == 0) revert ProposalNotQueued();
        if (proposalExecutionTime[proposal.executionPayloadHash] > block.timestamp) revert TimelockDelayNotMet();

        proposalExecutionTime[proposal.executionPayloadHash] = 0;

        MetaTransaction[] memory transactions = abi.decode(payload, (MetaTransaction[]));
        for (uint i = 0; i < transactions.length; i++) {
            (bool success, ) = transactions[i].to.call{ value: transactions[i].value }(transactions[i].data);
            if (!success) revert TransactionsFailed();
        }
    }

    function getStrategyType() external pure override returns (string memory) {
        return "SimpleQuorumTimelock";
    }
}
