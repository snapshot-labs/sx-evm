// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { GasSnapshot } from "forge-gas-snapshot/GasSnapshot.sol";

import "../../src/Space.sol";
import "../../src/authenticators/VanillaAuthenticator.sol";
import "../../src/voting-strategies/VanillaVotingStrategy.sol";
import "../../src/execution-strategies/VanillaExecutionStrategy.sol";

abstract contract SpaceTest is Test, GasSnapshot, ISpaceEvents, SpaceErrors {
    bytes4 constant PROPOSE_SELECTOR = bytes4(keccak256("propose(address,string,(address,bytes),(uint8,bytes)[])"));

    Space space;
    VanillaVotingStrategy vanillaVotingStrategy;
    VanillaAuthenticator vanillaAuthenticator;
    VanillaExecutionStrategy vanillaExecutionStrategy;

    uint256 public constant authorKey = 1234;
    uint256 public constant voterKey = 5678;

    // Address of the meta transaction relayer
    address public relayer = address(this);
    address public owner = address(1);
    address public author = vm.addr(authorKey);
    address public voter = vm.addr(voterKey);
    address public unauthorized = address(4);

    Strategy[] votingStrategies;
    address[] authenticators;
    Strategy executionStrategy;
    Strategy[] executionStrategies;
    address[] executionStrategiesAddresses;

    uint32 public votingDelay;
    uint32 public minVotingDuration;
    uint32 public maxVotingDuration;
    uint256 public proposalThreshold;
    uint32 public quorum;

    IndexedStrategy[] public userVotingStrategies;

    // TODO: emit in the space factory event - (once we have a factory)
    string public spaceMetadataUri = "SOC Test Space";

    string public proposalMetadataUri = "SOC Test Proposal";

    function setUp() public virtual {
        vanillaVotingStrategy = new VanillaVotingStrategy();
        vanillaAuthenticator = new VanillaAuthenticator();
        vanillaExecutionStrategy = new VanillaExecutionStrategy();

        votingDelay = 0;
        minVotingDuration = 1;
        maxVotingDuration = 1000;
        proposalThreshold = 1;
        quorum = 1;
        votingStrategies.push(Strategy(address(vanillaVotingStrategy), new bytes(0)));
        authenticators.push(address(vanillaAuthenticator));
        executionStrategy = Strategy(address(0), new bytes(0));
        executionStrategies.push(executionStrategy);
        userVotingStrategies.push(IndexedStrategy(0, new bytes(0)));
        executionStrategiesAddresses.push(executionStrategy.addy);

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
            executionStrategiesAddresses
        );
    }
}
