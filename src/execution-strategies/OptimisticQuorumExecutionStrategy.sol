// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../interfaces/IExecutionStrategy.sol";

abstract contract OptimisticQuorumExecutionStrategy is IExecutionStrategy {
    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external virtual override;

    function getProposalStatus(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain
    ) public view override returns (ProposalStatus) {
        // Decode the quorum parameter from the execution strategy's params
        uint256 quorum = abi.decode(proposal.executionStrategy.params, (uint256));
        bool rejected = votesAgainst >= quorum;
        if (proposal.finalizationStatus == FinalizationStatus.Cancelled) {
            return ProposalStatus.Cancelled;
        } else if (proposal.finalizationStatus == FinalizationStatus.Executed) {
            return ProposalStatus.Executed;
        } else if (block.timestamp < proposal.startTimestamp) {
            return ProposalStatus.VotingDelay;
        } else if (block.timestamp < proposal.minEndTimestamp) {
            return ProposalStatus.VotingPeriod;
        } else if (block.timestamp < proposal.maxEndTimestamp) {
            if (rejected) {
                return ProposalStatus.Rejected;
            } else {
                return ProposalStatus.VotingPeriod;
            }
        } else if (rejected) {
            return ProposalStatus.Rejected;
        } else {
            return ProposalStatus.Accepted;
        }
    }
}
