// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@gnosis.pm/safe-contracts/contracts/libraries/MultiSend.sol";
import "./mocks/Avatar.sol";
import "../src/execution-strategies/AvatarExecutionStrategy.sol";

contract AvatarExecutionStrategyTest is Test {
    error SpaceNotEnabled();
    error TransactionsFailed();

    address owner = address(1);
    address unauthorized = address(2);

    TestAvatar public avatar;

    MultiSend public multiSend;

    AvatarExecutionStrategy public avatarExecutionStrategy;

    function setUp() public {
        multiSend = new MultiSend();
        avatar = new TestAvatar();
        vm.deal(address(avatar), 1000);

        address[] memory spaces = new address[](1);
        // We use this test contract as a dummy space contract for the test.
        spaces[0] = address(this);
        avatarExecutionStrategy = new AvatarExecutionStrategy(owner, address(avatar), address(multiSend), spaces);

        avatar.enableModule(address(avatarExecutionStrategy));
    }

    function testAvatarExecutionStrategySingleTx() public {
        // Creating a transaction that will send 1 wei to the owner
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(address(owner), 1, "", Enum.Operation.Call);

        assertEq(owner.balance, 0); // sanity check
        avatarExecutionStrategy.execute(ProposalOutcome.Accepted, abi.encode(transactions));
        // owner should have received 1 wei
        assertEq(owner.balance, 1);
    }

    function testAvatarExecutionStrategyMultiTx() public {
        MetaTransaction[] memory transactions = new MetaTransaction[](2);
        transactions[0] = MetaTransaction(address(owner), 1, "", Enum.Operation.Call);
        // Creating a transaction that will enable a new dummy module on the avatar
        transactions[1] = MetaTransaction(
            address(avatar),
            0,
            abi.encodeWithSignature("enableModule(address)", address(0xbeef)),
            Enum.Operation.Call
        );

        assertEq(owner.balance, 0); // sanity check
        assertEq(avatar.isModuleEnabled(address(0xbeef)), false); // sanity check
        avatarExecutionStrategy.execute(ProposalOutcome.Accepted, abi.encode(transactions));
        // owner should have received 1 wei
        assertEq(owner.balance, 1);
        // dummy module should have been enabled
        assertEq(avatar.isModuleEnabled(address(0xbeef)), true);
    }

    function testAvatarExecutionStrategyInvalidTx() public {
        // This transaction will fail because the avatar does not have enough funds
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(address(owner), 1001, "", Enum.Operation.Call);

        vm.expectRevert(TransactionsFailed.selector);
        avatarExecutionStrategy.execute(ProposalOutcome.Accepted, abi.encode(transactions));
    }

    function testAvatarExecutionStrategyInvalidCaller() public {
        // Creating a transaction that will send 1 wei to the owner
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(address(owner), 1, "", Enum.Operation.Call);

        // Only whitelisted spaces can call the execute function
        vm.prank(unauthorized);
        vm.expectRevert(SpaceNotEnabled.selector);
        avatarExecutionStrategy.execute(ProposalOutcome.Accepted, abi.encode(transactions));
    }
}
