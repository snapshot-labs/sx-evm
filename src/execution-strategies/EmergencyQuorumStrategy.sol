// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IExecutionStrategy } from "../interfaces/IExecutionStrategy.sol";
import { FinalizationStatus, Proposal, ProposalStatus } from "../types.sol";

abstract contract EmergencyQuorumStrategy is IExecutionStrategy {
    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external virtual override;

    // solhint-disable-next-line code-complexity
    function getProposalStatus(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain
    ) public view override returns (ProposalStatus) {
        // Decode the quorum and emergencyQuorum from the execution strategy's params
        (uint256 quorum, uint256 emergencyQuorum) = abi.decode(proposal.executionStrategy.params, (uint256, uint256));

        bool emergency = _quorumReached(emergencyQuorum, votesFor, votesAgainst, votesAbstain);
        bool emergencyAccepted = emergency && _supported(votesFor, votesAgainst);

        // If emergencyAccepted is `true` then the proposal is necessarily `accepted`. This is an edge case where
        // `emergencyQuorum < quorum`.
        bool accepted = emergencyAccepted ||
            (_quorumReached(quorum, votesFor, votesAgainst, votesAbstain) && _supported(votesFor, votesAgainst));

        if (proposal.finalizationStatus == FinalizationStatus.Cancelled) {
            return ProposalStatus.Cancelled;
        } else if (proposal.finalizationStatus == FinalizationStatus.Executed) {
            return ProposalStatus.Executed;
        } else if (block.timestamp < proposal.startTimestamp) {
            return ProposalStatus.VotingDelay;
        } else if (block.timestamp < proposal.minEndTimestamp) {
            // Emergency code is inserted here.
            if (emergency) {
                if (emergencyAccepted) {
                    return ProposalStatus.VotingPeriodAccepted;
                } else {
                    return ProposalStatus.Rejected;
                }
            } else {
                return ProposalStatus.VotingPeriod;
            }
        } else if (block.timestamp < proposal.maxEndTimestamp) {
            if (accepted) {
                return ProposalStatus.VotingPeriodAccepted;
            } else {
                return ProposalStatus.VotingPeriod;
            }
        } else if (accepted) {
            return ProposalStatus.Accepted;
        } else {
            return ProposalStatus.Rejected;
        }
    }

    function _quorumReached(
        uint256 _quorum,
        uint256 _votesFor,
        uint256 _votesAgainst,
        uint256 _votesAbstain
    ) internal pure returns (bool) {
        uint256 totalVotes = _votesFor + _votesAgainst + _votesAbstain;
        return totalVotes >= _quorum;
    }

    function _supported(uint256 _votesFor, uint256 _votesAgainst) internal pure returns (bool) {
        return _votesFor > _votesAgainst;
    }
}
