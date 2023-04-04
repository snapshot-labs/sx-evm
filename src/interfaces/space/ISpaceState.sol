// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Choice, Proposal, ProposalStatus, FinalizationStatus, Strategy } from "src/types.sol";
import { IExecutionStrategy } from "src/interfaces/IExecutionStrategy.sol";

interface ISpaceState {
    function maxVotingDuration() external view returns (uint32);

    function minVotingDuration() external view returns (uint32);

    function nextProposalId() external view returns (uint256);

    function votingDelay() external view returns (uint32);

    function votingStrategies(uint8 index) external view returns (address addr, bytes memory params);

    function proposalValidationStrategy() external view returns (address addr, bytes memory params);

    function voteRegistry(uint256 proposalId, address voter) external view returns (bool);

    function votePower(uint256 proposalId, Choice choice) external view returns (uint256);

    // function proposalRegistry(uint256 proposalId) external view returns (Proposal memory);
    function proposalRegistry(
        uint256 proposalId
    )
        external
        view
        returns (
            uint32 snapshotTimestamp,
            uint32 startTimestamp,
            uint32 minEndTimestamp,
            uint32 maxEndTimestamp,
            bytes32 executionPayloadHash,
            IExecutionStrategy executionStrategy,
            address author,
            FinalizationStatus finalizationStatus,
            uint256 activeVotingStrategies
        );

    function getProposalStatus(uint256 proposalId) external view returns (ProposalStatus);

    function hasVoted(uint256 proposalId, address voter) external view returns (bool);
}
