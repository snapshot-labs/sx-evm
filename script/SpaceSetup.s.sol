// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { ProxyFactory } from "../src/ProxyFactory.sol";
import { Space } from "../src/Space.sol";
import { Strategy } from "../src/types.sol";

// solhint-disable-next-line max-states-count
contract SpaceSetup is Script {
    using stdJson for string;

    ProxyFactory public proxyFactory;
    address public spaceImplementation;
    address public vanillaVotingStrategy;
    address public compVotingStrategy;
    address public whitelistStrategy;
    address public vanillaAuthenticator;
    address public ethSigAuthenticator;
    address public ethTxAuthenticator;
    address public avatarExecutionStrategyImplementation;
    address public vanillaExecutionStrategy;

    Space public space;

    address public controller;
    uint32 public votingDelay;
    uint32 public minVotingDuration;
    uint32 public maxVotingDuration;
    uint256 public proposalThreshold;
    uint32 public quorum;
    string internal metadataURI = "SX Test Space";

    // function run() public {
    //     uint256 pvk = vm.envUint("PRIVATE_KEY");
    //     controller = vm.rememberKey(pvk);

    //     string memory network = vm.envString("NETWORK");
    //     string memory deployments = vm.readFile(string.concat(string.concat("./deployments/", network), ".json"));

    //     proxyFactory = ProxyFactory(deployments.readAddress("ProxyFactory"));
    //     spaceImplementation = deployments.readAddress("SpaceImplementation");
    //     vanillaVotingStrategy = deployments.readAddress("VanillaVotingStrategy");
    //     compVotingStrategy = deployments.readAddress("CompVotingStrategy");
    //     whitelistStrategy = deployments.readAddress("WhitelistStrategy");
    //     vanillaAuthenticator = deployments.readAddress("VanillaAuthenticator");
    //     ethSigAuthenticator = deployments.readAddress("EthSigAuthenticator");
    //     ethTxAuthenticator = deployments.readAddress("EthTxAuthenticator");
    //     vanillaExecutionStrategy = deployments.readAddress("VanillaExecutionStrategy");
    //     avatarExecutionStrategyImplementation = deployments.readAddress("AvatarExecutionStrategyImplementation");

    //     Strategy[] memory votingStrategies = new Strategy[](2);
    //     bytes[] memory votingStrategyMetadata = new bytes[](2);
    //     votingStrategies[0] = Strategy(vanillaVotingStrategy, new bytes(0));
    //     votingStrategyMetadata[0] = new bytes(0);
    //     address uni = address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984); // Goerli UNI token
    //     votingStrategies[1] = Strategy(compVotingStrategy, abi.encode(uni));
    //     votingStrategyMetadata[1] = new bytes(18); // UNI token decimals

    //     address[] memory authenticators = new address[](3);
    //     authenticators[0] = vanillaAuthenticator;
    //     authenticators[1] = ethSigAuthenticator;
    //     authenticators[2] = ethTxAuthenticator;
    //     Strategy[] memory executionStrategies = new Strategy[](1);
    //     executionStrategies[0] = Strategy(vanillaExecutionStrategy, new bytes(quorum));
    //     votingDelay = 0;
    //     minVotingDuration = 0;
    //     maxVotingDuration = 1000;
    //     proposalThreshold = 1;
    //     quorum = 1;
    //     votingPowerProposalValidationStrategy = Strategy(
    //         votingPowerProposalValidationContract,
    //         abi.encode(proposalThreshold, votingStrategies)
    //     );
    //     uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    //     vm.startBroadcast(deployerPrivateKey);
    //     spaceFactory.deployProxy(
    //         masterSpace,
    //         abi.encodeWithSelector(
    //             Space.initialize.selector,
    //             owner,
    //             votingDelay,
    //             minVotingDuration,
    //             maxVotingDuration,
    //             votingPowerProposalValidationStrategy,
    //             metadataURI,
    //             votingStrategies,
    //             votingStrategyMetadata,
    //             authenticators,
    //             executionStrategies
    //         ),
    //         keccak256(abi.encodePacked("SOC Test Space: 2"))
    //     );

    //     vm.stopBroadcast();
    // }
}
