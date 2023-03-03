// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IndexedStrategy, Proposal, Strategy, Vote, Choice } from "src/types.sol";

interface ISpaceEvents {
    event ProposalCreated(uint256 nextProposalId, address author, Proposal proposal, string metadataUri, bytes payload);
    event VoteCast(uint256 proposalId, address voterAddress, Choice choice, uint256 votingPower);
    event VoteCastWithMetadata(
        uint256 proposalId,
        address voterAddress,
        Choice choice,
        uint256 votingPower,
        string metadataUri
    );
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event VotingStrategiesAdded(Strategy[] votingStrategies, bytes[] data);
    event VotingStrategiesRemoved(uint8[] indices);
    event ExecutionStrategiesAdded(Strategy[] executionStrategies);
    event ExecutionStrategiesRemoved(uint8[] executionStrategies);
    event AuthenticatorsAdded(address[] authenticators);
    event AuthenticatorsRemoved(address[] authenticators);
    event ControllerUpdated(address newController);
    event MaxVotingDurationUpdated(uint32 newMaxVotingDuration);
    event MinVotingDurationUpdated(uint32 newMinVotingDuration);
    event MetadataUriUpdated(string newMetadataUri);
    event ProposalThresholdUpdated(uint256 newProposalThreshold);
    event QuorumUpdated(uint256 newQuorum);
    event VotingDelayUpdated(uint256 newVotingDelay);
    event ProposalUpdated(uint256 proposalId, IndexedStrategy newStrategy, string newMetadataUri);
}
