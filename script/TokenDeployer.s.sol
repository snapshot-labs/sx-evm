// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { ERC20, ERC20Permit, ERC20VotesComp } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";

contract TokenDeployer is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new Snap();
        vm.stopBroadcast();
    }
}

contract Snap is ERC20VotesComp {
    constructor() ERC20("Snap", "SNAP") ERC20Permit("Snap") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
