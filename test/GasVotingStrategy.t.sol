// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { GasVotingStrategy } from "../src/voting-strategies/GasVotingStrategy.sol";

contract GasVotingStrategyTest is Test {
    GasVotingStrategy public gasVotingStrategy;

    function setUp() public {
        gasVotingStrategy = new GasVotingStrategy();
    }

    function testGetVotingPower() public {
        // The voting power should always be 1.
        assertEq(vanillaVotingStrategy.getVotingPower(0, address(0), "", ""), 1);
    }
}
