// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Strategy } from "../../types.sol";

interface ISpaceOwnerActions {
    function cancel(uint256 proposalId) external;

    function updateStrategies(
        Strategy calldata _proposalValidationStrategy,
        address[] calldata _authenticatorsToAdd,
        address[] calldata _authenticatorsToRemove,
        Strategy[] calldata _votingStrategiesToAdd,
        string[] calldata _votingStrategyMetadataURIsToAdd,
        uint8[] calldata _votingIndicesToRemove
    ) external;

    function updateSettings(
        uint32 _minVotingDuration,
        uint32 _maxVotingDuration,
        uint32 _votingDelay,
        string calldata _metadataURI
    ) external;
}
