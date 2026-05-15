// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IExecutionStrategy } from "../interfaces/IExecutionStrategy.sol";
import { FinalizationStatus, Proposal, ProposalStatus } from "../types.sol";
import { SpaceManager } from "../utils/SpaceManager.sol";

/// @title Simple Quorum Base Execution Strategy
abstract contract SimpleQuorumExecutionStrategy is IExecutionStrategy, SpaceManager {
    event QuorumUpdated(uint256 newQuorum);

    /// @notice The quorum required to execute a proposal using this strategy.
    uint256 public quorum;

    /// @dev Initializer
    // solhint-disable-next-line func-name-mixedcase
    function __SimpleQuorumExecutionStrategy_init(uint256 _quorum) internal onlyInitializing {
        quorum = _quorum;
    }

    function setQuorum(uint256 _quorum) external onlyOwner {
        quorum = _quorum;
        emit QuorumUpdated(_quorum);
    }

    /// @inheritdoc IExecutionStrategy
    function getQuorum() external view override returns (uint256) {
        return quorum;
    }

    function execute(
        uint256 proposalId,
        Proposal memory proposal,
        bool quorumReached,
        bool supportAchieved,
        bytes memory payload
    ) external virtual override;

    /// @notice Returns the status of a proposal that uses a simple quorum.
    ///        A proposal is accepted if support is achieved and quorum is reached.
    /// @param proposal The proposal struct.
    /// @param quorumReached Whether the quorum has been reached.
    /// @param supportAchieved Whether the proposal has enough support.
    function getProposalStatus(
        Proposal memory proposal,
        bool quorumReached,
        bool supportAchieved
    ) public view override returns (ProposalStatus) {
        bool accepted = quorumReached && supportAchieved;
        if (proposal.finalizationStatus == FinalizationStatus.Cancelled) {
            return ProposalStatus.Cancelled;
        } else if (proposal.finalizationStatus == FinalizationStatus.Executed) {
            return ProposalStatus.Executed;
        } else if (block.number < proposal.startBlockNumber) {
            return ProposalStatus.VotingDelay;
        } else if (block.number < proposal.minEndBlockNumber) {
            return ProposalStatus.VotingPeriod;
        } else if (block.number < proposal.maxEndBlockNumber) {
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

    function getStrategyType() external view virtual override returns (string memory);
}
