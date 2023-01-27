// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../types.sol";

interface ISpaceFactory {
    event SpaceCreated(
        address space,
        address owner,
        uint32 votingDelay,
        uint32 minVotingDuration,
        uint32 maxVotingDuration,
        uint256 proposalThreshold,
        uint256 quorum,
        Strategy[] votingStrategies,
        address[] authenticators,
        address[] executionStrategiesAddresses
    );

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
