// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@gnosis.pm/safe-contracts/contracts/libraries/MultiSend.sol";
import "@zodiac/test/TestAvatar.sol";
import "../src/execution-strategies/AvatarExecutionStrategy.sol";

contract AvatarExecutionStrategyTest is Test {
    address owner = address(1);

    TestAvatar public avatar;

    MultiSend public multiSend;

    AvatarExecutionStrategy public avatarExecutionStrategy;

    function setUp() public {
        multiSend = new MultiSend();
        avatar = new TestAvatar();
        vm.deal(address(avatar), 1000);

        address[] memory spaces = new address[](1);
        spaces[0] = address(this);
        avatarExecutionStrategy = new AvatarExecutionStrategy(owner, address(avatar), address(multiSend), spaces);

        avatar.enableModule(address(avatarExecutionStrategy));
    }

    function testAvatarExecutionStrategy() public {
        address[] memory targets = new address[](1);
        targets[0] = address(avatar);

        uint256[] memory values = new uint256[](1);
        values[0] = 1;

        bytes[] memory data = new bytes[](1);
        data[0] = hex"";

        Enum.Operation[] memory operations = new Enum.Operation[](1);
        operations[0] = Enum.Operation.Call;

        bytes memory executionParams = encodeExecution(targets, values, data, operations);


        avatarExecutionStrategy.execute(ProposalOutcome.Accepted, executionParams);
    }

    function encodeExecution(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data,
        Enum.Operation[] memory operations
    ) public pure returns (bytes memory) {
        bytes memory encodedExecution = hex"";
        for (uint256 i; i < targets.length; i++) {
            encodedExecution = abi.encodePacked(
                encodedExecution,
                abi.encodePacked(
                    uint8(operations[i]), 
                    targets[i],
                    values[i], 
                    uint256(data[i].length), 
                    data[i]
                )
            );
        }
        return encodedExecution;
    }
}

