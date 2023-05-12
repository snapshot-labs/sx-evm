// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Strategy } from "../../types.sol";

/// @title Space Owner Actions
/// @notice The actions that can be performed by the owner of a Space,
///         These are in addition to the methods exposed by the `OwnableUpgradeable` module and the
///         `upgradeTo()` method of `UUPSUpgradeable`.
interface ISpaceOwnerActions {
    /// @notice  Cancels a proposal that has not already been finalized.
    /// @param   proposalId  The proposal to cancel.
    function cancel(uint256 proposalId) external;

    /// @notice Updates the different strategies.
    /// @param _proposalValidationStrategy The new proposal validation strategy to use. Set
    ///                                    to `NO_UPDATE_PROPOSAL_STRATEGY` to ignore.
    /// @param _authenticatorsToAdd The authenticators to add. Set to an empty array to ignore.
    /// @param _authenticatorsToRemove The authenticators to remove. Set to an empty array to ignore.
    /// @param _votingStrategiesToAdd The voting strategies to add. Set to an empty array to ignore.
    /// @param _votingStrategyMetadataURIsToAdd The voting strategy metadata uris to add. Set to
    ///                                         an empty array to ignore.
    function updateStrategies(
        Strategy calldata _proposalValidationStrategy,
        address[] calldata _authenticatorsToAdd,
        address[] calldata _authenticatorsToRemove,
        Strategy[] calldata _votingStrategiesToAdd,
        string[] calldata _votingStrategyMetadataURIsToAdd,
        uint8[] calldata _votingIndicesToRemove
    ) external;

    /// @notice Updates the settings.
    /// @param _minVotingDuration The new minimum voting duration. Set to `NO_UPDATE_DURATION` to ignore.
    /// @param _maxVotingDuration The new maximum voting duration. Set to `NO_UPDATE_DURATION` to ignore.
    /// @param _votingDelay The new voting delay. Set to `NO_UPDATE_DURATION` to ignore.
    /// @param _metadataURI The new metadataURI. Set to `NO_UPDATE_METADATA_URI` to ignore.
    function updateSettings(
        uint32 _minVotingDuration,
        uint32 _maxVotingDuration,
        uint32 _votingDelay,
        string calldata _metadataURI
    ) external;
}
