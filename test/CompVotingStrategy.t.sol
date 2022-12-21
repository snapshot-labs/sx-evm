// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/voting-strategies/CompVotingStrategy.sol";
import "./mocks/CompToken.sol";

contract CompVotingStrategyTest is Test {
    CompVotingStrategy public compVotingStrategy;
    CompToken public compToken;

    function setUp() public {
        compVotingStrategy = new CompVotingStrategy();
        compToken = new CompToken();
    }

    function testGetVotingPower() public {
        compToken.mint(address(this), 1);
        // Must delegate to self to activate checkpoints
        compToken.delegate(address(this));
        vm.roll(block.number+1);
        assertEq(
            compVotingStrategy.getVotingPower(block.timestamp, address(this), abi.encodePacked(address(compToken)), ""),
            1
        );
    }
}
