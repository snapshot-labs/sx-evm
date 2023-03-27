// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IExecutionStrategy } from "../interfaces/IExecutionStrategy.sol";
import { FinalizationStatus, Proposal, ProposalStatus } from "../types.sol";
import { SpaceManager } from "../utils/SpaceManager.sol";

abstract contract SimpleQuorumExecutionStrategy is IExecutionStrategy, SpaceManager {
    uint256 public quorum;

    // solhint-disable-next-line func-name-mixedcase
    function __SimpleQuorumExecutionStrategy_init(uint256 _quorum) internal onlyInitializing {
        quorum = _quorum;
    }

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
        bool accepted = _quorumReached(quorum, votesFor, votesAgainst, votesAbstain) &&
            _supported(votesFor, votesAgainst);
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

    function getStrategyType() external view virtual override returns (string memory);
}
