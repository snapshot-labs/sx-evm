// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../types.sol";
import "./ISpaceFactoryEvents.sol";

interface ISpaceFactory is ISpaceFactoryEvents {
    function createSpace(
        address owner,
        uint32 votingDelay,
        uint32 minVotingDuration,
        uint32 maxVotingDuration,
        uint256 proposalThreshold,
        uint256 quorum,
        Strategy[] calldata votingStrategies,
        address[] calldata authenticators,
        address[] calldata executionStrategiesAddresses,
        bytes32 salt
    ) external;
}
