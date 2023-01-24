// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Space.sol";
import "../src/authenticators/VanillaAuthenticator.sol";
import "../src/voting-strategies/VanillaVotingStrategy.sol";
import "../src/execution-strategies/VanillaExecutionStrategy.sol";

contract VanillaSpaceSetup is Script {

    Space public space;
    VanillaVotingStrategy public vanillaVotingStrategy;
    VanillaAuthenticator public vanillaAuthenticator;
    VanillaExecutionStrategy public vanillaExecutionStrategy;

    address public owner;

    Strategy[] public votingStrategies;
    address[] public authenticators;
    Strategy public executionStrategy;
    Strategy[] public executionStrategies;
    address[] public executionStrategiesAddresses;

    uint32 public votingDelay;
    uint32 public minVotingDuration;
    uint32 public maxVotingDuration;
    uint256 public proposalThreshold;
    uint32 public quorum;

    IndexedStrategy[] public userVotingStrategies;

    // TODO: emit in the space factory event - (once we have a factory)
    string public spaceMetadataUri = "SOC Test Space";

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        vanillaVotingStrategy = new VanillaVotingStrategy();
        vanillaAuthenticator = new VanillaAuthenticator();
        vanillaExecutionStrategy = new VanillaExecutionStrategy();

        votingDelay = 0;
        minVotingDuration = 0;
        maxVotingDuration = 1000;
        proposalThreshold = 1;
        quorum = 1;
        votingStrategies.push(Strategy(address(vanillaVotingStrategy), new bytes(0)));
        authenticators.push(address(vanillaAuthenticator));
        executionStrategy = Strategy(address(vanillaExecutionStrategy), new bytes(0));
        executionStrategies.push(executionStrategy);
        userVotingStrategies.push(IndexedStrategy(0, new bytes(0)));
        executionStrategiesAddresses.push(executionStrategy.addy);

        owner = vm.envAddress("OWNER");

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


        vm.stopBroadcast();


    }
}
