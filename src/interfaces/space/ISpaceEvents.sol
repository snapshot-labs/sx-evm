// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "src/types.sol";

interface ISpaceEvents {
    event ProposalCreated(
        uint256 nextProposalId,
        address proposerAddress,
        Proposal proposal,
        string metadataUri,
        bytes executionParams
    );
    event VoteCreated(uint256 proposalId, address voterAddress, Vote vote);
    event ProposalFinalized(uint256 proposalId, ProposalOutcome outcome);

    event VotingStrategiesAdded(Strategy[] votingStrategies);
    event VotingStrategiesRemoved(uint8[] indices);
    event ExecutionStrategiesAdded(address[] executionStrategies);
    event ExecutionStrategiesRemoved(address[] executionStrategies);
    event AuthenticatorsAdded(address[] authenticators);
    event AuthenticatorsRemoved(address[] authenticators);
    event ControllerUpdated(address newController);
    event MaxVotingDurationUpdated(uint32 newMaxVotingDuration);
    event MinVotingDurationUpdated(uint32 newMinVotingDuration);
    event MetadataUriUpdated(string newMetadataUri);
    event ProposalThresholdUpdated(uint256 newProposalThreshold);
    event QuorumUpdated(uint256 newQuorum);
    event VotingDelayUpdated(uint256 newVotingDelay);
}
