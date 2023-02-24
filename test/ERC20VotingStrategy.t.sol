// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/voting-strategies/ERC20VotingStrategy.sol";
import "./mocks/ERC20VotesToken.sol";

contract ERC20VotingStrategyTest is Test {
    error InvalidByteArray();

    ERC20VotingStrategy public erc20VotingStrategy;
    ERC20VotesToken public erc20VotesToken;

    address public user = address(this);
    address public user2 = address(1);

    function setUp() public {
        erc20VotingStrategy = new ERC20VotingStrategy();
        erc20VotesToken = new ERC20VotesToken("VOTES", "VOTES");
    }

    function testGetVotingPower() public {
        erc20VotesToken.mint(user, 1);
        // Must delegate to self to activate checkpoints
        erc20VotesToken.delegate(user);
        vm.roll(block.number + 1);
        assertEq(
            erc20VotingStrategy.getVotingPower(uint32(block.timestamp), user, abi.encodePacked(address(erc20VotesToken)), ""),
            1
        );
    }

    function testGetZeroVotingPower() public {
        erc20VotesToken.mint(user, 1);
        // No delegation, so voting power is zero
        vm.roll(block.number + 1);
        assertEq(
            erc20VotingStrategy.getVotingPower(uint32(block.timestamp), user, abi.encodePacked(address(erc20VotesToken)), ""),
            0
        );
    }

    function testGetVotingPowerInvalidToken() public {
        erc20VotesToken.mint(user, 1);
        erc20VotesToken.delegate(user);
        vm.roll(block.number + 1);
        vm.expectRevert();
        // Token address is set to zero
        erc20VotingStrategy.getVotingPower(uint32(block.timestamp), user, abi.encodePacked(address(0)), "");
    }

    function testGetVotingPowerInvalidParamsArray() public {
        erc20VotesToken.mint(user, 1);
        erc20VotesToken.delegate(user);
        vm.roll(block.number + 1);
        vm.expectRevert(InvalidByteArray.selector);
        // Params array is too short
        erc20VotingStrategy.getVotingPower(uint32(block.timestamp), user, abi.encodePacked("1234"), "");
    }
}
