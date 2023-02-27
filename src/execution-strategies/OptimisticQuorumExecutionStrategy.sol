// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../interfaces/IExecutionStrategy.sol";

contract OptimisticQuorumExecutionStrategy is IExecutionStrategy {
    uint256 numExecuted;

    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external override {
        ProposalStatus proposalStatus = getProposalStatus(proposal, votesFor, votesAgainst, votesAbstain);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }
        // Check that the execution payload matches the payload supplied when the proposal was created
        if (proposal.executionPayloadHash != keccak256(payload)) revert InvalidPayload();
        numExecuted++;
    }

    function getProposalStatus(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain
    ) public view override returns (ProposalStatus) {
        // Decode the quorum parameter from the execution strategy's params
        uint256 quorum = abi.decode(proposal.executionStrategy.params, (uint256));
        bool accepted = votesAgainst < quorum;
        if (proposal.finalizationStatus == FinalizationStatus.Cancelled) {
            return ProposalStatus.Cancelled;
        } else if (proposal.finalizationStatus == FinalizationStatus.Executed) {
            return ProposalStatus.Executed;
        } else if (block.timestamp < proposal.startTimestamp) {
            return ProposalStatus.VotingDelay;
        } else if (block.timestamp < proposal.minEndTimestamp) {
            return ProposalStatus.VotingPeriod;
        } else if (block.timestamp < proposal.maxEndTimestamp) {
            if (accepted) {
                return ProposalStatus.VotingPeriod;
            } else {
                return ProposalStatus.Rejected;
            }
        } else if (accepted) {
            return ProposalStatus.Accepted;
        } else {
            return ProposalStatus.Rejected;
        }
    }
}
