// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/voting-strategies/CompVotingStrategy.sol";
import "./mocks/CompToken.sol";

contract CompVotingStrategyTest is Test {
    error TimestampInFuture();
    error InvalidBytesArray();

    CompVotingStrategy public compVotingStrategy;
    CompToken public compToken;

    address public user = address(this);
    address public user2 = address(1);

    function setUp() public {
        compVotingStrategy = new CompVotingStrategy();
        compToken = new CompToken();
    }

    function testGetVotingPower() public {
        compToken.mint(user, 1);
        // Must delegate to self to activate checkpoints
        compToken.delegate(user);
        vm.roll(block.number + 1);
        assertEq(compVotingStrategy.getVotingPower(block.timestamp, user, abi.encodePacked(address(compToken)), ""), 1);
    }

    function testGetZeroVotingPower() public {
        compToken.mint(user, 1);
        // No delegation, so voting power is zero
        vm.roll(block.number + 1);
        assertEq(compVotingStrategy.getVotingPower(block.timestamp, user, abi.encodePacked(address(compToken)), ""), 0);
    }

    function testGetVotingPowerInvalidTimestamp() public {
        compToken.mint(user, 1);
        compToken.delegate(user);
        vm.roll(block.number + 1);
        vm.expectRevert(TimestampInFuture.selector);
        // Timestamp is set to the future
        compVotingStrategy.getVotingPower(block.timestamp + 1, user, abi.encodePacked(address(compToken)), "");
    }

    function testGetVotingPowerInvalidToken() public {
        compToken.mint(user, 1);
        compToken.delegate(user);
        vm.roll(block.number + 1);
        vm.expectRevert();
        // Token address is set to zero
        compVotingStrategy.getVotingPower(block.timestamp, user, abi.encodePacked(address(0)), "");
    }

    function testGetVotingPowerInvalidParamsArray() public {
        compToken.mint(user, 1);
        compToken.delegate(user);
        vm.roll(block.number + 1);
        vm.expectRevert(InvalidBytesArray.selector);
        // Params array is too short
        compVotingStrategy.getVotingPower(block.timestamp, user, abi.encodePacked("1234"), "");
    }

    function testTimestampResolver() public {
        compToken.mint(user, 1);
        compToken.delegate(user);
        vm.roll(block.number + 1);

        // Saving the snapshot timestamp
        uint256 snapshotTimestamp = block.timestamp;

        assertEq(
            compVotingStrategy.getVotingPower(snapshotTimestamp, user, abi.encodePacked(address(compToken)), ""),
            1
        ); // sanity check

        // The snapshot timestamp is resolved to the current block number - 1
        assertEq(compVotingStrategy.timestampToBlockNumber(snapshotTimestamp), block.number - 1);

        // Increasing the timestamp
        vm.warp(block.timestamp + 100);

        compToken.mint(user2, 1);
        compToken.delegate(user2);
        vm.roll(block.number + 1);

        // user2 has no voting power at the snapshot timestamp because the delegation happened after
        assertEq(
            compVotingStrategy.getVotingPower(snapshotTimestamp, user2, abi.encodePacked(address(compToken)), ""),
            0
        );

        // However at the current timestamp, the delegation is active
        assertEq(
            compVotingStrategy.getVotingPower(block.timestamp, user2, abi.encodePacked(address(compToken)), ""),
            1
        );
    }
}
