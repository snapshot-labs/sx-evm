// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../interfaces/IExecutionStrategy.sol";

abstract contract SimpleQuorumExecutionStrategy is IExecutionStrategy {
    // solhint-disable no-unused-vars
    function execute(
        Proposal memory proposal,
        bytes memory executionParams
    ) external virtual override returns (ProposalOutcome);

    function getProposalStatus(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain
    ) external view override returns (ProposalStatus) {
        if (proposal.finalizationStatus == FinalizationStatus.NotExecuted) {
            // Proposal has not been executed yet. Let's look at the current timestamp.
            if (block.timestamp < proposal.startTimestamp) {
                // Not started yet.
                return ProposalStatus.WaitingForVotingPeriodToStart;
            } else if (block.timestamp > proposal.maxEndTimestamp) {
                // Voting period is over, this proposal is waiting to be finalized.
                return ProposalStatus.Finalizable;
            } else {
                // We are somewhere between `proposal.startTimestamp` and `proposal.maxEndTimestamp`.
                if (block.timestamp > proposal.minEndTimestamp) {
                    // We've passed `proposal.minEndTimestamp`, check if quorum has been reached.
                    if (_quorumReached(proposal.quorum, votesFor, votesAgainst, votesAbstain)) {
                        // Quorum has been reached, this proposal is finalizable.
                        return ProposalStatus.VotingPeriodFinalizable;
                    } else {
                        // Quorum has not been reached so this proposal is NOT finalizable yet.
                        return ProposalStatus.VotingPeriod;
                    }
                } else {
                    // `proposal.minEndTimestamp` not reached, so we're just in the regular Voting Period.
                    return ProposalStatus.VotingPeriod;
                }
            }
        } else {
            // Proposal has been executed. Since `FinalizationStatus` and `ProposalStatus` only differ by
            // one, we can safely cast it by substracting 1.
            return ProposalStatus(uint8(proposal.finalizationStatus) - 1);
        }
    }

    function _quorumReached(
        uint256 quorum,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain
    ) internal pure returns (bool) {
        uint256 totalVotes = votesFor + votesAgainst + votesAbstain;
        return totalVotes >= quorum;
    }
}
