// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { GasSnapshot } from "forge-gas-snapshot/GasSnapshot.sol";

import "../src/Space.sol";
import "../src/authenticators/VanillaAuthenticator.sol";
import "../src/voting-strategies/VanillaVotingStrategy.sol";
import "../src/interfaces/space/ISpaceEvents.sol";

abstract contract SpaceTest is Test, GasSnapshot, ISpaceEvents {
    Space space;
    VanillaVotingStrategy vanillaVotingStrategy;
    VanillaAuthenticator vanillaAuthenticator;
    address vanillaExecutionStrategy;

    VotingStrategy[] votingStrategies;
    address[] authenticators;
    address[] executionStrategies;
    
    uint32 public votingDelay;
    uint32 public minVotingDuration;
    uint32 public maxVotingDuration;
    uint256 public proposalThreshold;
    uint32 public quorum;

    bytes public executionParams;
    uint256[] public usedVotingStrategiesIndices;
    bytes[] public userVotingStrategyParams;

    address public owner = address(this);

    // TODO: emit in the space factory event - (once we have a factory)
    string public spaceMetadataUri = "SOC Test Space";

    string public proposalMetadataUri = "SOC Test Proposal";

    function setUp() public {
        vanillaVotingStrategy = new VanillaVotingStrategy();
        vanillaAuthenticator = new VanillaAuthenticator();
        // TODO: deploy vanilla execution strategy once it's implemented

        votingDelay = 0;
        minVotingDuration = 1;
        maxVotingDuration = 1000;
        proposalThreshold = 1;
        quorum = 1;
        votingStrategies.push(VotingStrategy(address(vanillaVotingStrategy), new bytes(0)));
        authenticators.push(address(vanillaAuthenticator));
        executionStrategies.push(address(0));
        usedVotingStrategiesIndices = [0];
        userVotingStrategyParams = [new bytes(0)];
        executionParams = new bytes(0);

        owner = address(this);

        space = new Space(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            authenticators,
            executionStrategies
        );
 
    }
}