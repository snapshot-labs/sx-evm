// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Choice, Proposal, ProposalStatus, Strategy } from "src/types.sol";

interface ISpaceState {
    function maxVotingDuration() external view returns (uint32);

    function minVotingDuration() external view returns (uint32);

    function nextProposalId() external view returns (uint256);

    function votingDelay() external view returns (uint32);

    // Returns `Strategy` but can't override the default derived implementation
    function votingStrategies(uint256 index) external view returns (address addr, bytes memory params);

    // Returns `Strategy` but can't override the default derived implementation
    function proposalValidationStrategy() external view returns (address addr, bytes memory params);

    function voteRegistry(uint256 proposalId, address voter) external view returns (bool);

    function votePower(uint256 proposalId, Choice choice) external view returns (uint256);

    function getProposal(uint256 proposalId) external view returns (Proposal memory);

    function getProposalStatus(uint256 proposalId) external view returns (ProposalStatus);

    function hasVoted(uint256 proposalId, address voter) external view returns (bool);
}
