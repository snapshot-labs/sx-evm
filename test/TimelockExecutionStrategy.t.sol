// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { Choice, Enum, IndexedStrategy, MetaTransaction, ProposalStatus, Strategy, Proposal } from "../src/types.sol";
import { TimelockExecutionStrategy } from "../src/execution-strategies/TimelockExecutionStrategy.sol";
import { MockImplementation } from "./mocks/MockImplementation.sol";

contract TimelockExecutionStrategyTest is SpaceTest {
    error TransactionsFailed();
    error TimelockDelayNotMet();
    error ProposalNotQueued();
    error DuplicateExecutionPayloadHash();
    event TransactionQueued(MetaTransaction transaction, uint256 executionTime);

    TimelockExecutionStrategy public timelockExecutionStrategy;

    address private recipient = address(0xc0ffee);

    function setUp() public override {
        super.setUp();

        address[] memory spaces = new address[](1);
        spaces[0] = address(space);

        timelockExecutionStrategy = new TimelockExecutionStrategy(owner, spaces, 1000);
        vm.deal(address(timelockExecutionStrategy), 1000);

        // Activate the execution strategy on the space
        Strategy[] memory executionStrategies = new Strategy[](1);
        executionStrategies[0] = Strategy(address(timelockExecutionStrategy), abi.encode(uint256(quorum)));
        // This strategy will reside at index 1 in the space's execution strategies array
        space.addExecutionStrategies(executionStrategies);
    }

    function testQueueingFromUnauthorizedSpace() external {
        timelockExecutionStrategy.disableSpace(address(space));

        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        vm.expectRevert();
        space.execute(proposalId, abi.encode(transactions));
    }

    function testQueueing() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        space.execute(proposalId, abi.encode(transactions));
    }

    function testQueueingFailedProposal() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        vm.warp(block.timestamp + space.maxVotingDuration());

        vm.expectRevert();
        space.execute(proposalId, abi.encode(transactions));
    }

    function testQueueingDoubleQueue() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        space.execute(proposalId, abi.encode(transactions));

        vm.expectRevert();
        space.execute(proposalId, abi.encode(transactions));
    }

    function testQueueingQueueDuplicate() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        uint256 proposalId2 = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        _vote(author, proposalId2, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        space.execute(proposalId, abi.encode(transactions));

        // Will revert due to duplicate execution payload hash
        vm.expectRevert(DuplicateExecutionPayloadHash.selector);
        space.execute(proposalId2, abi.encode(transactions));
    }

    function testQueueingInvalidPayload() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        transactions[0] = MetaTransaction(recipient, 2, "", Enum.Operation.Call);

        vm.expectRevert(InvalidPayload.selector);
        space.execute(proposalId, abi.encode(transactions));
    }

    function testExecute() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        space.execute(proposalId, abi.encode(transactions));

        assertEq(recipient.balance, 0);

        vm.warp(block.timestamp + timelockExecutionStrategy.TIMELOCK_DELAY());
        timelockExecutionStrategy.execute(abi.encode(transactions));

        assertEq(recipient.balance, 1);
    }

    function testExecuteTransactionFailed() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1001, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        space.execute(proposalId, abi.encode(transactions));

        vm.warp(block.timestamp + timelockExecutionStrategy.TIMELOCK_DELAY());

        vm.expectRevert(TransactionsFailed.selector);
        timelockExecutionStrategy.execute(abi.encode(transactions));
    }

    function testExecuteInvalidPayload() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        space.execute(proposalId, abi.encode(transactions));

        vm.warp(block.timestamp + timelockExecutionStrategy.TIMELOCK_DELAY());
        transactions[0] = MetaTransaction(recipient, 2, "", Enum.Operation.Call);

        vm.expectRevert(ProposalNotQueued.selector);
        timelockExecutionStrategy.execute(abi.encode(transactions));
    }

    function testExecuteBeforeDelay() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        space.execute(proposalId, abi.encode(transactions));

        vm.expectRevert(TimelockDelayNotMet.selector);
        timelockExecutionStrategy.execute(abi.encode(transactions));
    }

    function testExecuteNotQueued() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        vm.expectRevert(ProposalNotQueued.selector);
        timelockExecutionStrategy.execute(abi.encode(transactions));
    }

    function testExecuteDoubleExecution() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        space.execute(proposalId, abi.encode(transactions));

        assertEq(recipient.balance, 0);

        vm.warp(block.timestamp + timelockExecutionStrategy.TIMELOCK_DELAY());
        timelockExecutionStrategy.execute(abi.encode(transactions));

        vm.expectRevert();
        timelockExecutionStrategy.execute(abi.encode(transactions));
    }

    function testExecuteDelegateCall() external {
        MockImplementation impl = new MockImplementation();

        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(
            address(impl),
            0,
            abi.encodeWithSignature("transferEth(address,uint256)", recipient, 1),
            Enum.Operation.DelegateCall
        );
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataUri,
            IndexedStrategy(1, abi.encode(transactions)),
            userVotingStrategies
        );
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri);
        vm.warp(block.timestamp + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        space.execute(proposalId, abi.encode(transactions));

        assertEq(recipient.balance, 0);

        vm.warp(block.timestamp + timelockExecutionStrategy.TIMELOCK_DELAY());
        timelockExecutionStrategy.execute(abi.encode(transactions));

        assertEq(recipient.balance, 1);
    }
}
