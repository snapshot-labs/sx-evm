// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { Space } from "../src/Space.sol";
import { VanillaAuthenticator } from "../src/authenticators/VanillaAuthenticator.sol";
import { VanillaVotingStrategy } from "../src/voting-strategies/VanillaVotingStrategy.sol";
import { VanillaExecutionStrategy } from "../src/execution-strategies/VanillaExecutionStrategy.sol";
import { AvatarExecutionStrategy } from "../src/execution-strategies/AvatarExecutionStrategy.sol";
import { EthSigAuthenticator } from "../src/authenticators/EthSigAuthenticator.sol";
import { EthTxAuthenticator } from "../src/authenticators/EthTxAuthenticator.sol";
import { CompVotingStrategy } from "../src/voting-strategies/CompVotingStrategy.sol";
import { WhitelistStrategy } from "../src/voting-strategies/WhitelistStrategy.sol";
import { ProxyFactory } from "../src/ProxyFactory.sol";

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
        uint32 chainId = getChainId(network);

        deploymentsPath = string.concat(string.concat("./deployments/", network), ".json");

        vm.startBroadcast(deployer);

        string memory json = "deploymentArtifact";
        (address vanillaExecutionStrategy, ) = noRedeploy(type(VanillaExecutionStrategy).creationCode);
        json.serialize("VanillaExecutionStrategy", vanillaExecutionStrategy);

        (address avatarExecutionStrategy, ) = noRedeploy(type(AvatarExecutionStrategy).creationCode);
        // TODO: initialize avatar implementation
        // AvatarExecutionStrategy(avatarExecutionStrategy).
        // setUp(abi.encode(address(0x1), address(0x1), new address[](0)));
        json.serialize("AvatarExecutionStrategyImplementation", avatarExecutionStrategy);

        (address compVotingStrategy, ) = noRedeploy(type(CompVotingStrategy).creationCode);
        json.serialize("CompVotingStrategy", compVotingStrategy);

        (address vanillaAuthenticator, ) = noRedeploy(type(VanillaAuthenticator).creationCode);
        json.serialize("VanillaAuthenticator", vanillaAuthenticator);

        (address ethTxAuthenticator, ) = noRedeploy(type(EthTxAuthenticator).creationCode);
        json.serialize("EthTxAuthenticator", ethTxAuthenticator);

        (address ethSigAuthenticator, ) = noRedeploy(
            abi.encodePacked(type(EthSigAuthenticator).creationCode, abi.encode(name, version))
        );
        json.serialize("EthSigAuthenticator", ethSigAuthenticator);

        (address vanillaVotingStrategy, ) = noRedeploy(type(VanillaVotingStrategy).creationCode);
        json.serialize("VanillaVotingStrategy", vanillaVotingStrategy);

        (address whitelistStrategy, ) = noRedeploy(type(WhitelistStrategy).creationCode);
        json.serialize("WhitelistStrategy", whitelistStrategy);

        (address proxyFactory, ) = noRedeploy(type(ProxyFactory).creationCode);
        json.serialize("ProxyFactory", proxyFactory);

        (address space, ) = noRedeploy(abi.encodePacked(type(Space).creationCode, abi.encode(name, version, chainId)));
        // TODO: initialize space implementation
        json = json.serialize("SpaceImplementation", space);

        json.write(deploymentsPath);

        vm.stopBroadcast();
    }

    function getChainId(string memory network) internal view returns (uint32) {
        string memory json = vm.readFile("./deployments/chains.json");
        return abi.decode(vm.parseJson(json, string.concat(network, ".id")), (uint32));
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

    function labelAndRecord(address addy, string memory contractName) internal {
        vm.label(addy, contractName);
        vm.writeJson(vm.serializeAddress(deployments, contractName, addy), deploymentsPath);
    }
}
