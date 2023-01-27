// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "../src/SpaceFactory.sol";
import "../src/interfaces/ISpaceFactoryEvents.sol";
import "./utils/Space.t.sol";

// Using `SpaceTest` for easy setup
contract SpaceFactoryTest is SpaceTest, ISpaceFactoryEvents {
    function testCreateSpace() public {
        SpaceFactory factory = new SpaceFactory();

        // Ensure the event gets fired properly.
        vm.expectEmit(true, true, true, true);
        emit SpaceCreated(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            authenticators,
            executionStrategiesAddresses
        );

        factory.createSpace(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            authenticators,
            executionStrategiesAddresses,
            bytes32(0)
        );
    }
}
