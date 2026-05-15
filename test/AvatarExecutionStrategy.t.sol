// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { Avatar } from "./mocks/Avatar.sol";
import { AvatarExecutionStrategy } from "../src/execution-strategies/AvatarExecutionStrategy.sol";
import { Enum, IndexedStrategy, MetaTransaction, ProposalStatus, Strategy, TRUE, FALSE } from "../src/types.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

abstract contract AvatarExecutionStrategyTest is SpaceTest {
    error InvalidSpace();

    event AvatarExecutionStrategySetUp(address _owner, address _target, address[] _spaces, uint256 _quorum);
    event TargetSet(address indexed newTarget);
    event SpaceEnabled(address space);
    event SpaceDisabled(address space);

    Avatar public avatar;
    AvatarExecutionStrategy public avatarExecutionStrategy;

    address private recipient = address(0xc0ffee);

    function setUp() public virtual override {
        super.setUp();

        avatar = new Avatar();
        vm.deal(address(avatar), 1000);
    }

    function testExecution() public {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(avatarExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        _tryExecute(proposalId, abi.encode(transactions));

        // recipient should have received 1 wei
        assertEq(recipient.balance, 1);
        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Executed));
    }

    function testExecutionProposalNotAccepted() public {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(avatarExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, abi.encode(transactions));
        // Proposal should NOT be executed since it was rejected (no votes)
        assertTrue(uint8(space.getProposalStatus(proposalId)) != uint8(ProposalStatus.Executed));
    }

    function testExecutionInvalidPayload() public {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(avatarExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        transactions[0] = MetaTransaction(recipient, 2, "", Enum.Operation.Call, 0);

        _tryExecuteExpectRevert(proposalId, abi.encode(transactions), abi.encodeWithSelector(InvalidPayload.selector));
    }

    function testInvalidTx() public {
        // This transaction will fail because the avatar does not have enough funds
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(address(spaceOwner), 1001, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(avatarExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecuteExpectRevert(proposalId, abi.encode(transactions), abi.encodeWithSelector(ExecutionFailed.selector));
    }

    function testMultiTx() public {
        MetaTransaction[] memory transactions = new MetaTransaction[](2);
        transactions[0] = MetaTransaction(address(recipient), 1, "", Enum.Operation.Call, 0);
        // Creating a transaction that will enable a new dummy module on the avatar
        transactions[1] = MetaTransaction(
            address(avatar),
            0,
            abi.encodeWithSignature("enableModule(address)", address(0xbeef)),
            Enum.Operation.Call,
            0
        );
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(avatarExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        assertEq(recipient.balance, 0); // sanity check
        assertEq(avatar.isModuleEnabled(address(0xbeef)), false); // sanity check
        _tryExecute(proposalId, abi.encode(transactions));
        assertEq(recipient.balance, 1);
        assertEq(avatar.isModuleEnabled(address(0xbeef)), true);
    }

    function testInvalidMultiTx() public {
        MetaTransaction[] memory transactions = new MetaTransaction[](2);
        transactions[0] = MetaTransaction(
            address(avatar),
            0,
            abi.encodeWithSignature("enableModule(address)", address(0xbeef)),
            Enum.Operation.Call,
            0
        );
        // invalid tx
        transactions[1] = MetaTransaction(address(spaceOwner), 1001, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(avatarExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecuteExpectRevert(proposalId, abi.encode(transactions), abi.encodeWithSelector(ExecutionFailed.selector));
        // both txs should have reverted despite the first one being valid
        assertEq(recipient.balance, 0);
        assertEq(avatar.isModuleEnabled(address(0xbeef)), false);
    }

    function testSetTarget() public {
        address newTarget = address(0xbeef);
        vm.prank(spaceOwner);
        vm.expectEmit(true, true, true, true);
        emit TargetSet(newTarget);
        avatarExecutionStrategy.setTarget(newTarget);
        assertEq(address(avatarExecutionStrategy.target()), newTarget);
    }

    function testUnauthorizedSetTarget() public {
        address newTarget = address(0xbeef);
        vm.prank(unauthorized);
        _expectOnlyOwnerRevert(unauthorized);
        avatarExecutionStrategy.setTarget(newTarget);
    }

    function testTransferOwnership() public {
        address newOwner = address(0xbeef);
        vm.prank(spaceOwner);
        avatarExecutionStrategy.transferOwnership(newOwner);
        assertEq(address(avatarExecutionStrategy.owner()), newOwner);
    }

    function testUnauthorizedTransferOwnership() public {
        address newOwner = address(0xbeef);
        vm.prank(unauthorized);
        _expectOnlyOwnerRevert(unauthorized);
        avatarExecutionStrategy.transferOwnership(newOwner);
    }

    function testDoubleInitialization() public {
        _expectInvalidInitializationRevert();
        address[] memory spaces = new address[](1);
        spaces[0] = address(this);
        avatarExecutionStrategy.setUp(abi.encode(spaceOwner, address(avatar), spaces));
    }

    function testEnableSpace() public {
        address space = address(0xbeef);
        vm.prank(spaceOwner);
        vm.expectEmit(true, true, true, true);
        emit SpaceEnabled(space);
        avatarExecutionStrategy.enableSpace(space);
        assertEq(avatarExecutionStrategy.isSpaceEnabled(space), TRUE);
    }

    function testEnableInvalidSpace() public {
        // The zero address is not a valid space
        address space = address(0);
        vm.prank(spaceOwner);
        vm.expectRevert(InvalidSpace.selector);
        avatarExecutionStrategy.enableSpace(space);
    }

    function testEnableSpaceTwice() public {
        vm.prank(spaceOwner);
        vm.expectRevert(InvalidSpace.selector);
        avatarExecutionStrategy.enableSpace(address(space));
    }

    function testUnauthorizedEnableSpace() public {
        address space = address(0xbeef);
        vm.prank(unauthorized);
        _expectOnlyOwnerRevert(unauthorized);
        avatarExecutionStrategy.enableSpace(space);
    }

    function testDisableSpace() public {
        vm.prank(spaceOwner);
        vm.expectEmit(true, true, true, true);
        emit SpaceDisabled(address(space));
        avatarExecutionStrategy.disableSpace(address(space));
        assertEq(avatarExecutionStrategy.isSpaceEnabled(address(space)), FALSE);

        // Check that proposals from the disabled space can't be executed
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(avatarExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecuteExpectRevert(proposalId, abi.encode(transactions), abi.encodeWithSelector(InvalidSpace.selector));
    }

    function testDisableInvalidSpace() public {
        // This space is not enabled
        address space = address(0xbeef);
        vm.prank(spaceOwner);
        vm.expectRevert(InvalidSpace.selector);
        avatarExecutionStrategy.disableSpace(space);
    }

    function testUnauthorizedDisableSpace() public {
        vm.prank(unauthorized);
        _expectOnlyOwnerRevert(unauthorized);
        avatarExecutionStrategy.disableSpace(address(space));
    }

    function testGetStrategyType() external view {
        assertEq(avatarExecutionStrategy.getStrategyType(), "SimpleQuorumAvatar");
    }
}

contract AvatarExecutionStrategyTestDirect is AvatarExecutionStrategyTest {
    function setUp() public override {
        super.setUp();

        address[] memory spaces = new address[](1);
        spaces[0] = address(space);
        vm.expectEmit(true, true, true, true);
        emit AvatarExecutionStrategySetUp(spaceOwner, address(avatar), spaces, quorum);
        avatarExecutionStrategy = new AvatarExecutionStrategy(spaceOwner, address(avatar), spaces, quorum);
        avatar.enableModule(address(avatarExecutionStrategy));
    }
}

contract AvatarExecutionStrategyTestProxy is AvatarExecutionStrategyTest {
    function setUp() public override {
        super.setUp();

        address[] memory spaces = new address[](1);
        spaces[0] = address(space);
        vm.expectEmit(true, true, true, true);
        emit AvatarExecutionStrategySetUp(spaceOwner, address(avatar), spaces, quorum);
        AvatarExecutionStrategy masterAvatarExecutionStrategy = new AvatarExecutionStrategy(
            spaceOwner,
            address(avatar),
            spaces,
            quorum
        );

        avatarExecutionStrategy = AvatarExecutionStrategy(
            address(
                new ERC1967Proxy(
                    address(masterAvatarExecutionStrategy),
                    abi.encodeWithSelector(
                        AvatarExecutionStrategy.setUp.selector,
                        abi.encode(spaceOwner, address(avatar), spaces, quorum)
                    )
                )
            )
        );
        avatar.enableModule(address(avatarExecutionStrategy));
    }
}
