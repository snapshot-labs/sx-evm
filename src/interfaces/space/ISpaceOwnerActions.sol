// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ISpaceOwnerActions {
    function cancelProposal(uint256 proposalId) external;

    function setController(uint256 controller) external;

    function setQuorum(uint256 quorum) external;

    function setVotingDelay(uint32 delay) external;

    function setMinVotingDuration(uint32 duration) external;

    function setMaxVotingDuration(uint32 duration) external;

    function setProposalThreshold(uint256 threshold) external;

    function setMetadataUri(string calldata metadataUri) external;

    function addVotingStrategies(
        address[] calldata _votingStrategies,
        bytes[] calldata _votingStrategiesParams
    ) external;

    function removeVotingStrategies(uint256[] calldata indicesToRemove) external;

    function addAuthenticators() external;

    function removeAuthenticators() external;

    function addExecutionStrategies() external;

    function removeExecutionStrategies() external;
}
