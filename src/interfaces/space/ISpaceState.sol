// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ISpaceState {
    function hasVoted(uint256 proposalId, address voter) external view returns (bool);

    function getProposalInfo(uint256 proposalId) external view returns (bool);

    function maxVotingDuration() external view returns (uint32);

    function minVotingDuration() external view returns (uint32);

    function nextProposalNonce() external view returns (uint256);

    function proposalThreshold() external view returns (uint256);

    function quorum() external view returns (uint256);

    function votingDelay() external view returns (uint32);
}
