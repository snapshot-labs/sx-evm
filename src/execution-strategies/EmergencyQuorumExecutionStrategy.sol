// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IExecutionStrategy } from "../interfaces/IExecutionStrategy.sol";
import { FinalizationStatus, Proposal, ProposalStatus } from "../types.sol";
import { SpaceManager } from "../utils/SpaceManager.sol";

abstract contract EmergencyQuorumExecutionStrategy is IExecutionStrategy, SpaceManager {
    uint256 public quorum;
    uint256 public emergencyQuorum;

    event QuorumUpdated(uint256 _quorum);
    event EmergencyQuorumUpdated(uint256 _emergencyQuorum);

    /// @dev Initializer
    // solhint-disable-next-line func-name-mixedcase
    function __EmergencyQuorumExecutionStrategy_init(
        uint256 _quorum,
        uint256 _emergencyQuorum
    ) internal onlyInitializing {
        quorum = _quorum;
        emergencyQuorum = _emergencyQuorum;
    }

    function setQuorum(uint256 _quorum) external onlyOwner {
        quorum = _quorum;
        emit QuorumUpdated(_quorum);
    }

    function setEmergencyQuorum(uint256 _emergencyQuorum) external onlyOwner {
        emergencyQuorum = _emergencyQuorum;
        emit EmergencyQuorumUpdated(_emergencyQuorum);
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

    // solhint-disable-next-line code-complexity
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
}
