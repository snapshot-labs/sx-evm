// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";

import { EthTxAuthenticator } from "../src/authenticators/EthTxAuthenticator.sol";

interface SingletonFactory {
    function deploy(bytes memory _initCode, bytes32 salt) external returns (address payable);
}

contract Deployer is Script {
    address internal deployer;
    string internal deployments;
    string internal deploymentsPath;
    bytes32 internal salt = bytes32(0); //keccak256(abi.encodePacked("SX DEPLOYER SALT 0"));

    function run() public {
        uint256 pvk = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(pvk);

        string memory network = vm.envString("NETWORK");
        uint32 chainId = getChainId(network);

        bool redeploy = false;
        try vm.envBool("REDEPLOY") returns (bool a) {
            redeploy = a;
        } catch {}

        string memory dep_loc = "./deployments/";
        string memory dep_path = string.concat(dep_loc, network);
        deploymentsPath = string.concat(dep_path, ".json");
        if (!redeploy) {
            try vm.readFile(deploymentsPath) returns (string memory prev_dep) {
                deployments = prev_dep;
            } catch {
                // create the file
                vm.writeFile(deploymentsPath, "{}");
            }
        } else {
            // create the file if it doesnt exist, overwrite it if it does
            vm.writeFile(deploymentsPath, "{}");
        }
        vm.startBroadcast(pvk);
        SingletonFactory singletonFactory = SingletonFactory(0xce0042B868300000d44A59004Da54A005ffdcf9f);
        address addy = singletonFactory.deploy(abi.encodePacked(type(EthTxAuthenticator).creationCode), salt);
        // (address ps, ) = noRedeploy(type(VanillaAuthenticator).creationCode, "VanillaAuthenticator");
        vm.stopBroadcast();
    }

    function getChainId(string memory network) internal view returns (uint32) {
        string memory json = vm.readFile("./deployments/chains.json");
        return abi.decode(vm.parseJson(json, string.concat(network, ".id")), (uint32));
    }

    // Prevents redeployment to a chain
    function noRedeploy(bytes memory _initCode, string memory contractName) internal returns (address, bool) {
        // check if the contract name is in deployments
        try vm.parseJson(deployments, contractName) returns (bytes memory deployedTo) {
            if (deployedTo.length > 0) {
                address someContract = abi.decode(deployedTo, (address));
                // some networks are ephemeral so we need to actually confirm it was deployed
                // by checking if code is nonzero
                if (someContract.code.length > 0) {
                    vm.label(someContract, contractName);
                    // we already have it deployed
                    return (someContract, false);
                }
            }
        } catch {}
        vm.startBroadcast(deployer);
        address addy = singletonFactory.deploy(_initCode, salt);
        vm.stopBroadcast();
        labelAndRecord(addy, contractName);
        return (addy, true);
    }

    function labelAndRecord(address addy, string memory contractName) internal {
        vm.label(addy, contractName);
        vm.writeFile(deploymentsPath, vm.serializeAddress(deployments, contractName, addy));
    }
}
