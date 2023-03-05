// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { Choice, Enum, IndexedStrategy, MetaTransaction, ProposalStatus, Strategy, Proposal } from "../src/types.sol";
import { TimelockExecutionStrategy } from "../src/execution-strategies/TimelockExecutionStrategy.sol";

contract TimelockExecutionStrategyTest is SpaceTest {
    error TimelockDelayNotMet();
    error ProposalNotQueued();
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

        Proposal memory proposal = space.getProposal(proposalId);

        vm.expectRevert(TimelockDelayNotMet.selector);
        timelockExecutionStrategy.execute(proposal, abi.encode(transactions));
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

        Proposal memory proposal = space.getProposal(proposalId);

        vm.expectRevert(ProposalNotQueued.selector);
        timelockExecutionStrategy.execute(proposal, abi.encode(transactions));
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

        vm.warp(block.timestamp + timelockExecutionStrategy.timelockDelay());
        timelockExecutionStrategy.execute(space.getProposal(proposalId), abi.encode(transactions));

        assertEq(recipient.balance, 1);
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

        Proposal memory proposal = space.getProposal(proposalId);

        vm.warp(block.timestamp + timelockExecutionStrategy.timelockDelay());
        timelockExecutionStrategy.execute(proposal, abi.encode(transactions));

        vm.expectRevert();
        timelockExecutionStrategy.execute(proposal, abi.encode(transactions));
    }
}
