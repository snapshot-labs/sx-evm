// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Strategy } from "../../types.sol";

interface ISpaceOwnerActions {
    function cancel(uint256 proposalId) external;

    function setVotingDelay(uint32 delay) external;

    function setMinVotingDuration(uint32 duration) external;

    function setMaxVotingDuration(uint32 duration) external;

    function setProposalValidationStrategy(Strategy calldata proposalValidationStrategy) external;

    function setMetadataURI(string calldata metadataURI) external;

    function addVotingStrategies(
        Strategy[] calldata votingStrategies,
        string[] calldata votingStrategiesMetadataURIs
    ) external;

    function removeVotingStrategies(uint8[] calldata indicesToRemove) external;

    function addAuthenticators(address[] calldata _authenticators) external;

    function removeAuthenticators(address[] calldata _authenticators) external;

    function updateAuthenticators(address[] calldata _toAdd, address[] calldata _toRemove) external;

    function updateVotingStrategies(
        Strategy[] calldata _votingStrategies,
        string[] calldata _votingStrategiesMetadataURIs,
        uint8[] calldata _indicesToRemove
    ) external;

    function updateSettings(
        uint32 _maxVotingDuration,
        uint32 _minVotingDuration,
        string calldata _metadataURI,
        Strategy calldata _proposalValidationStrategy,
        uint32 _votingDelay,
        address[] calldata _authenticatorsToAdd,
        address[] calldata _authenticatorsToRemove,
        Strategy[] calldata _votingStrategiesToAdd,
        string[] calldata _votingStrategiesMetadataURIsToAdd,
        uint8[] calldata _indicesToRemove
    ) external;
}
