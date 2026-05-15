// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import {
    Enum,
    IndexedStrategy,
    MetaTransaction,
    ProposalStatus,
    Strategy,
    Proposal,
    TRUE,
    FALSE
} from "../src/types.sol";
import {
    OptimisticCompTimelockCompatibleExecutionStrategy
} from "../src/execution-strategies/timelocks/OptimisticCompTimelockCompatibleExecutionStrategy.sol";
import { MockImplementation } from "./mocks/MockImplementation.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TestERC1155 } from "./mocks/TestERC1155.sol";
import { TestERC721 } from "./mocks/TestERC721.sol";
import { CompTimelock } from "./mocks/CompTimelock.sol";

// Most tests are similar to `CompTimelockExecutionStrategyTest.t.sol`.
abstract contract OptimisticCompTimelockExecutionStrategyTest is SpaceTest {
    error InvalidSpace();
    error TimelockDelayNotMet();
    error ProposalNotQueued();
    error DuplicateExecutionPayloadHash();
    error DuplicateMetaTransaction();
    error OnlyVetoGuardian();
    error InvalidTransaction();

    event OptimisticCompTimelockCompatibleExecutionStrategySetUp(
        address owner,
        address vetoGuardian,
        address[] spaces,
        uint256 quorum,
        address timelock
    );
    event TransactionQueued(MetaTransaction transaction, uint256 executionTime);
    event ProposalVetoed(bytes32 executionPayloadHash);
    event VetoGuardianSet(address vetoGuardian, address newVetoGuardian);

    OptimisticCompTimelockCompatibleExecutionStrategy public timelockExecutionStrategy;
    CompTimelock public timelock = new CompTimelock(address(this), 1000);

    address public emptyVetoGuardian = address(0);
    address public recipient = address(0xc0ffee);

    function finishSetUp() public {
        vm.deal(address(spaceOwner), 1000);
        payable(timelock).transfer(1000);

        bytes memory callData = abi.encodeWithSignature("setPendingAdmin(address)", address(timelockExecutionStrategy));
        uint256 eta = block.timestamp + 1000;
        timelock.queueTransaction(address(timelock), 0, "", callData, eta);

        vm.warp(vm.getBlockTimestamp() + 1000);

        timelock.executeTransaction(address(timelock), 0, "", callData, eta);

        timelockExecutionStrategy.acceptAdmin();
    }

    function testQueueingFromUnauthorizedSpace() external {
        timelockExecutionStrategy.disableSpace(address(space));

        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.warp(vm.getBlockTimestamp() + space.maxVotingDuration());

        _tryExecuteExpectRevert(proposalId, abi.encode(transactions), abi.encodeWithSelector(InvalidSpace.selector));
    }

    function testQueueing() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        // Under the new tryExecute flow, proposals are only processed for execution
        // after a positive support signal is produced by voting.
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        _tryExecute(proposalId, abi.encode(transactions));
    }

    function testQueueingDuplicateMetaTransaction() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](2);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        // Salt differs but content does not
        transactions[1] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 1);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecuteExpectRevert(
            proposalId,
            abi.encode(transactions),
            abi.encodeWithSelector(DuplicateMetaTransaction.selector)
        );
    }

    function testQueueingDuplicateMetaTransactionDifferentProposals() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);

        MetaTransaction[] memory duplicateTransactions = new MetaTransaction[](1);
        // Salt differs but content does not
        duplicateTransactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 1);

        // Create and approve the first proposal.
        uint256 firstProposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, firstProposalId, 1, userVotingStrategies, voteMetadataURI);

        // Create a second proposal with the same transactions, and vote on it.
        uint256 secondProposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(duplicateTransactions)),
            new bytes(0)
        );
        _vote(voter, secondProposalId, 1, userVotingStrategies, voteMetadataURI);

        // Move forward in time.
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        // Queue the first one: it should work properly.
        _tryExecute(firstProposalId, abi.encode(transactions));

        // Ensure an error is thrown for the second proposal!
        _tryExecuteExpectRevert(
            secondProposalId,
            abi.encode(duplicateTransactions),
            abi.encodeWithSelector(DuplicateMetaTransaction.selector)
        );
    }

    function testQueueingRejectedProposal() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 0, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, abi.encode(transactions));
        // Proposal should NOT be executed since it was rejected
        assertTrue(uint8(space.getProposalStatus(proposalId)) != uint8(ProposalStatus.Executed));
    }

    function testQueueingDoubleQueue() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        _tryExecute(proposalId, abi.encode(transactions));

        _tryExecuteExpectRevert(
            proposalId,
            abi.encode(transactions),
            abi.encodeWithSelector(ProposalFinalized.selector)
        );
    }

    function testQueueingQueueDuplicate() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        uint256 proposalId2 = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        _vote(voter, proposalId2, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, abi.encode(transactions));

        // Will revert due to duplicate execution payload hash
        _tryExecuteExpectRevert(
            proposalId2,
            abi.encode(transactions),
            abi.encodeWithSelector(DuplicateExecutionPayloadHash.selector)
        );
    }

    function testQueueingInvalidPayload() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        transactions[0] = MetaTransaction(recipient, 2, "", Enum.Operation.Call, 0);

        _tryExecuteExpectRevert(proposalId, abi.encode(transactions), abi.encodeWithSelector(InvalidPayload.selector));
    }

    function testExecute() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        _tryExecute(proposalId, abi.encode(transactions));

        assertEq(recipient.balance, 0);

        vm.warp(vm.getBlockTimestamp() + timelockExecutionStrategy.timelockDelay());
        timelockExecutionStrategy.executeQueuedProposal(abi.encode(transactions));

        assertEq(recipient.balance, 1);
    }

    function testExecuteTransactionFailed() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1001, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, abi.encode(transactions));

        vm.warp(vm.getBlockTimestamp() + timelockExecutionStrategy.timelockDelay());

        vm.expectRevert("Timelock::executeTransaction: Transaction execution reverted.");
        timelockExecutionStrategy.executeQueuedProposal(abi.encode(transactions));
    }

    function testExecuteInvalidPayload() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, abi.encode(transactions));

        vm.warp(vm.getBlockTimestamp() + timelockExecutionStrategy.timelockDelay());
        transactions[0] = MetaTransaction(recipient, 2, "", Enum.Operation.Call, 0);

        vm.expectRevert(ProposalNotQueued.selector);
        timelockExecutionStrategy.executeQueuedProposal(abi.encode(transactions));
    }

    function testExecuteBeforeDelay() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        _tryExecute(proposalId, abi.encode(transactions));

        vm.expectRevert(TimelockDelayNotMet.selector);
        timelockExecutionStrategy.executeQueuedProposal(abi.encode(transactions));
    }

    function testExecuteNotQueued() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        vm.expectRevert(ProposalNotQueued.selector);
        timelockExecutionStrategy.executeQueuedProposal(abi.encode(transactions));
    }

    function testExecuteDoubleExecution() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        _tryExecute(proposalId, abi.encode(transactions));

        assertEq(recipient.balance, 0);

        vm.warp(vm.getBlockTimestamp() + timelockExecutionStrategy.timelockDelay());
        timelockExecutionStrategy.executeQueuedProposal(abi.encode(transactions));

        vm.expectRevert(ProposalNotQueued.selector);
        timelockExecutionStrategy.executeQueuedProposal(abi.encode(transactions));
    }

    function testExecuteDelegateCall() external {
        MockImplementation impl = new MockImplementation();

        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(
            address(impl),
            0,
            abi.encodeWithSignature("transferEth(address,uint256)", recipient, 1),
            Enum.Operation.DelegateCall,
            0
        );
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecuteExpectRevert(
            proposalId,
            abi.encode(transactions),
            abi.encodeWithSelector(InvalidTransaction.selector)
        );
    }

    function testVetoProposal() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, abi.encode(transactions));

        // Set veto guardian
        address vetoGuardian = address(0x7e20);
        vm.expectEmit(true, true, true, true);
        emit VetoGuardianSet(address(0), vetoGuardian);
        timelockExecutionStrategy.setVetoGuardian(vetoGuardian);

        vm.prank(vetoGuardian);
        vm.expectEmit(true, true, true, true);
        emit ProposalVetoed(keccak256(abi.encode(transactions)));
        timelockExecutionStrategy.veto(abi.encode(transactions));

        vm.warp(vm.getBlockTimestamp() + timelockExecutionStrategy.timelockDelay());
        vm.expectRevert(ProposalNotQueued.selector);
        timelockExecutionStrategy.executeQueuedProposal(abi.encode(transactions));
    }

    function testVetoOnlyGuardian() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, abi.encode(transactions));

        address vetoGuardian = address(0x7e20);
        vm.prank(vetoGuardian);
        vm.expectRevert(OnlyVetoGuardian.selector);
        timelockExecutionStrategy.veto(abi.encode(transactions));
    }

    function testSetVetoGuardian() external {
        timelockExecutionStrategy.setVetoGuardian(address(0));

        vm.prank(voter);
        _expectOnlyOwnerRevert(voter);
        timelockExecutionStrategy.setVetoGuardian(address(1));
    }

    function testVetoProposalNotQueued() external {
        MetaTransaction[] memory transactions = new MetaTransaction[](1);
        transactions[0] = MetaTransaction(recipient, 1, "", Enum.Operation.Call, 0);
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);

        // Set veto guardian
        address vetoGuardian = address(0x7e20);
        vm.expectEmit(true, true, true, true);
        emit VetoGuardianSet(address(0), vetoGuardian);
        timelockExecutionStrategy.setVetoGuardian(vetoGuardian);

        vm.prank(vetoGuardian);
        vm.expectRevert(ProposalNotQueued.selector);
        timelockExecutionStrategy.veto(abi.encode(transactions));
    }

    function testExecuteNFTs() external {
        TestERC721 erc721 = new TestERC721();

        vm.startPrank(author);
        erc721.mint(author, 1);
        erc721.transferFrom(author, address(timelock), 1);
        vm.stopPrank();

        MetaTransaction[] memory transactions = new MetaTransaction[](2);
        transactions[0] = MetaTransaction(
            address(erc721),
            0,
            abi.encodeWithSelector(erc721.transferFrom.selector, address(timelock), author, 1),
            Enum.Operation.Call,
            0
        );

        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(timelockExecutionStrategy), abi.encode(transactions)),
            new bytes(0)
        );
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        vm.expectEmit(true, true, true, true);
        emit TransactionQueued(transactions[0], block.timestamp + 1000);
        _tryExecute(proposalId, abi.encode(transactions));

        assertEq(erc721.ownerOf(1), address(timelock));

        vm.warp(vm.getBlockTimestamp() + timelockExecutionStrategy.timelockDelay());
        timelockExecutionStrategy.executeQueuedProposal(abi.encode(transactions));

        assertEq(erc721.ownerOf(1), address(author));
    }

    function testViewFunctions() public view {
        assertEq(timelockExecutionStrategy.getStrategyType(), "CompTimelockCompatibleOptimisticQuorum");
    }

    function testSetUp() public {
        address[] memory spaces = new address[](1);
        spaces[0] = address(space);
        timelockExecutionStrategy = new OptimisticCompTimelockCompatibleExecutionStrategy(
            spaceOwner,
            emptyVetoGuardian,
            spaces,
            quorum,
            address(timelock)
        );

        assertEq(timelockExecutionStrategy.owner(), spaceOwner);
        assertEq(timelockExecutionStrategy.vetoGuardian(), emptyVetoGuardian);
        assertEq(timelockExecutionStrategy.quorum(), quorum);
        assertEq(address(timelockExecutionStrategy.timelock()), address(timelock));
        assertEq(timelockExecutionStrategy.isSpaceEnabled(address(space)), TRUE);
    }
}

contract OptimisticCompTimelockExecutionStrategyTestDirect is OptimisticCompTimelockExecutionStrategyTest {
    function setUp() public override {
        super.setUp();

        address[] memory spaces = new address[](1);
        spaces[0] = address(space);

        timelockExecutionStrategy = new OptimisticCompTimelockCompatibleExecutionStrategy(
            spaceOwner,
            emptyVetoGuardian,
            spaces,
            quorum,
            address(timelock)
        );

        finishSetUp();
    }
}

contract OptimisticCompTimelockExecutionStrategyTestProxy is OptimisticCompTimelockExecutionStrategyTest {
    function setUp() public override {
        super.setUp();

        address[] memory spaces = new address[](1);
        spaces[0] = address(space);
        address[] memory emptyArray = new address[](1);

        // solhint-disable-next-line max-line-length
        OptimisticCompTimelockCompatibleExecutionStrategy masterExecutionStrategy = new OptimisticCompTimelockCompatibleExecutionStrategy(
                address(1),
                address(0),
                emptyArray,
                0,
                address(0)
            );

        timelockExecutionStrategy = OptimisticCompTimelockCompatibleExecutionStrategy(
            payable(
                new ERC1967Proxy(
                    address(masterExecutionStrategy),
                    abi.encodeWithSelector(
                        OptimisticCompTimelockCompatibleExecutionStrategy.setUp.selector,
                        abi.encode(spaceOwner, emptyVetoGuardian, spaces, quorum, address(timelock))
                    )
                )
            )
        );

        finishSetUp();
    }
}
