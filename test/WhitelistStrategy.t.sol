// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/voting-strategies/WhitelistStrategy.sol";

contract WhitelistStrategyTest is Test {
    WhitelistStrategy public whitelistStrategy;

    function testWhitelistVotingPower() public {
        WhitelistStrategy.Member[] memory members = new WhitelistStrategy.Member[](2);
        members[0] = WhitelistStrategy.Member(address(42), 21);
        members[1] = WhitelistStrategy.Member(address(1337), 123);
        whitelistStrategy = new WhitelistStrategy(members);

        assertEq(whitelistStrategy.getVotingPower(0, members[0].addy, "", ""), members[0].vp);
        assertEq(whitelistStrategy.getVotingPower(0, members[1].addy, "", ""), members[1].vp);
        assertEq(whitelistStrategy.getVotingPower(0, address(1), "", ""), 0);
    }
}
