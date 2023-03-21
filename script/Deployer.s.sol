// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { Space } from "../src/Space.sol";
import { VanillaAuthenticator } from "../src/authenticators/VanillaAuthenticator.sol";
import { VanillaVotingStrategy } from "../src/voting-strategies/VanillaVotingStrategy.sol";
import { VanillaExecutionStrategy } from "../src/execution-strategies/VanillaExecutionStrategy.sol";
import { AvatarExecutionStrategy } from "../src/execution-strategies/AvatarExecutionStrategy.sol";
import { TimelockExecutionStrategy } from "../src/execution-strategies/TimelockExecutionStrategy.sol";
import { EthSigAuthenticator } from "../src/authenticators/EthSigAuthenticator.sol";
import { EthTxAuthenticator } from "../src/authenticators/EthTxAuthenticator.sol";
import { CompVotingStrategy } from "../src/voting-strategies/CompVotingStrategy.sol";
import { OZVotesVotingStrategy } from "../src/voting-strategies/OZVotesVotingStrategy.sol";
import { WhitelistStrategy } from "../src/voting-strategies/WhitelistStrategy.sol";
import {
    VanillaProposalValidationStrategy
} from "../src/proposal-validation-strategies/VanillaProposalValidationStrategy.sol";
import {
    VotingPowerProposalValidationStrategy
} from "../src/proposal-validation-strategies/VotingPowerProposalValidationStrategy.sol";
import { ProxyFactory } from "../src/ProxyFactory.sol";
import { Strategy } from "../src/types.sol";

interface SingletonFactory {
    function deploy(bytes memory _initCode, bytes32 salt) external returns (address payable);
}

contract Deployer is Script {
    SingletonFactory internal singletonFactory = SingletonFactory(0xce0042B868300000d44A59004Da54A005ffdcf9f);
    address internal deployer;
    string internal deployments;
    string internal deploymentsPath;

    string internal name = "snapshot-x";
    string internal version = "0.1.0";

    using stdJson for string;

    // Salt used for all singleton deployments
    bytes32 internal salt = keccak256(abi.encodePacked("SX_DEPLOYER_SALT"));

    function run() public {
        uint256 pvk = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(pvk);

        string memory network = vm.envString("NETWORK");

        deploymentsPath = string.concat(string.concat("./deployments/", network), ".json");

        vm.startBroadcast(deployer);

        // ------- Execution Strategies -------

        (address avatarExecutionStrategy, ) = noRedeploy(
            abi.encodePacked(
                type(AvatarExecutionStrategy).creationCode,
                abi.encode(address(0x1), address(0x1), new address[](0), 0)
            )
        );

        deployments.serialize("AvatarExecutionStrategyImplementation", avatarExecutionStrategy);

        (address timelockExecutionStrategy, ) = noRedeploy(
            abi.encodePacked(
                type(TimelockExecutionStrategy).creationCode,
                abi.encode(address(0x1), new address[](0), 0, 0)
            )
        );

        deployments.serialize("TimelockExecutionStrategyImplementation", timelockExecutionStrategy);

        // ------- AUTHENTICATORS -------

        (address vanillaAuthenticator, ) = noRedeploy(type(VanillaAuthenticator).creationCode);
        deployments.serialize("VanillaAuthenticator", vanillaAuthenticator);

        (address ethTxAuthenticator, ) = noRedeploy(type(EthTxAuthenticator).creationCode);
        deployments.serialize("EthTxAuthenticator", ethTxAuthenticator);

        (address ethSigAuthenticator, ) = noRedeploy(
            abi.encodePacked(type(EthSigAuthenticator).creationCode, abi.encode(name, version))
        );
        deployments.serialize("EthSigAuthenticator", ethSigAuthenticator);

        // ------- VOTING STRATEGIES -------

        (address vanillaVotingStrategy, ) = noRedeploy(type(VanillaVotingStrategy).creationCode);
        deployments.serialize("VanillaVotingStrategy", vanillaVotingStrategy);

        (address whitelistStrategy, ) = noRedeploy(type(WhitelistStrategy).creationCode);
        deployments.serialize("WhitelistVotingStrategy", whitelistStrategy);

        (address compVotingStrategy, ) = noRedeploy(type(CompVotingStrategy).creationCode);
        deployments.serialize("CompVotingStrategy", compVotingStrategy);

        (address ozVotesVotingStrategy, ) = noRedeploy(type(OZVotesVotingStrategy).creationCode);
        deployments.serialize("OZVotesVotingStrategy", ozVotesVotingStrategy);

        // ------- PROPOSAL VALIDATION STRATEGIES -------

        (address vanillaProposalValidationStrategy, ) = noRedeploy(
            type(VanillaProposalValidationStrategy).creationCode
        );
        deployments.serialize("VanillaProposalValidationStrategy", vanillaProposalValidationStrategy);

        (address votingPowerProposalValidationStrategy, ) = noRedeploy(
            type(VotingPowerProposalValidationStrategy).creationCode
        );
        deployments.serialize("VotingPowerProposalValidationStrategy", votingPowerProposalValidationStrategy);

        // ------- Factory -------

        (address proxyFactory, ) = noRedeploy(type(ProxyFactory).creationCode);
        deployments.serialize("ProxyFactory", proxyFactory);

        // ------- SPACE -------

        (address space, ) = noRedeploy(type(Space).creationCode);

        // if the master space is not initialized, initialize it to be unusable
        if (Space(space).owner() == address(0x0)) {
            Strategy[] memory emptyStrategyArray = new Strategy[](1);
            emptyStrategyArray[0] = Strategy(address(0x1), new bytes(0));
            string[] memory emptyStringArray = new string[](1);
            emptyStringArray[0] = "";
            address[] memory emptyAddressArray = new address[](1);
            emptyAddressArray[0] = address(0x1);
            Space(space).initialize(
                address(0x1),
                1,
                1,
                1,
                Strategy(address(0x1), new bytes(0)),
                "",
                emptyStrategyArray,
                emptyStringArray,
                emptyAddressArray
            );
        }

        deployments = deployments.serialize("SpaceImplementation", space);

        deployments.write(deploymentsPath);

        vm.stopBroadcast();
    }

    // Deploys contract if it doesn't exist, otherwise returns the create2 address
    function noRedeploy(bytes memory _initCode) internal returns (address, bool) {
        address addy = computeCreate2Address(salt, keccak256(_initCode), address(singletonFactory));
        if (addy.code.length == 0) {
            address _addy = singletonFactory.deploy(_initCode, salt);
            assert(_addy == addy);
            return (addy, true);
        } else {
            return (addy, false);
        }
    }
}
