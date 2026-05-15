// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { OptimisticQuorumExecutionStrategy } from "../src/execution-strategies/OptimisticQuorumExecutionStrategy.sol";
import { IndexedStrategy, Proposal, ProposalStatus, Strategy } from "../src/types.sol";

// Dummy implementation of the optimistic quorum
contract OptimisticExec is OptimisticQuorumExecutionStrategy {
    constructor(address _owner, uint256 _quorum) {
        setUp(abi.encode(_owner, _quorum));
    }

    function setUp(bytes memory initParams) public initializer {
        (address _owner, uint256 _quorum) = abi.decode(initParams, (address, uint256));
        __Ownable_init(_owner);
        __OptimisticQuorumExecutionStrategy_init(_quorum);
    }

    uint256 internal numExecuted;

    function execute(
        uint256 /* proposalId */,
        Proposal memory proposal,
        bool quorumReached,
        bool supportAchieved,
        bytes memory /* payload */
    ) external override {
        ProposalStatus proposalStatus = getProposalStatus(proposal, quorumReached, supportAchieved);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }
        numExecuted++;
    }

    function getStrategyType() external pure override returns (string memory) {
        return "OptimisticQuorumExecution";
    }
}

contract OptimisticTest is SpaceTest {
    event QuorumUpdated(uint256 newQuorum);

    OptimisticExec internal optimisticQuorumStrategy;

    function setUp() public virtual override {
        super.setUp();

        // Update Quorum. Will need 2 `NO` votes in order to be rejected.
        quorum = 2;
        optimisticQuorumStrategy = new OptimisticExec(spaceOwner, quorum);

        executionStrategy = Strategy(address(optimisticQuorumStrategy), new bytes(0));
    }

    function testOptimisticQuorumNoVotes() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, executionStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Accepted));
    }

    function testOptimisticQuorumOneVote() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        _vote(author, proposalId, 0, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, executionStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Accepted));
    }

    function testOptimisticQuorumReached() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        _vote(author, proposalId, 0, userVotingStrategies, voteMetadataURI);
        _vote(address(42), proposalId, 0, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, executionStrategy.params);
        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Accepted));
    }

    function testOptimisticQuorumEquality() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        // 2 votes for
        _vote(address(1), proposalId, 1, userVotingStrategies, voteMetadataURI);
        _vote(address(2), proposalId, 1, userVotingStrategies, voteMetadataURI);
        // 2 votes against
        _vote(address(11), proposalId, 0, userVotingStrategies, voteMetadataURI);
        _vote(address(12), proposalId, 0, userVotingStrategies, voteMetadataURI);

        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, executionStrategy.params);
        assertTrue(uint8(space.getProposalStatus(proposalId)) != uint8(ProposalStatus.Executed));
        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Rejected));
    }

    function testOptimisticQuorumMinVotingPeriodReached() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        _vote(address(11), proposalId, 0, userVotingStrategies, voteMetadataURI);
        _vote(address(12), proposalId, 0, userVotingStrategies, voteMetadataURI);

        vm.roll(vm.getBlockNumber() + space.minVotingDuration());

        _tryExecute(proposalId, executionStrategy.params);
        assertTrue(uint8(space.getProposalStatus(proposalId)) != uint8(ProposalStatus.Executed));
        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.VotingPeriodAccepted));
    }

    function testOptimisticQuorumMinVotingPeriodAccepted() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));

        vm.roll(vm.getBlockNumber() + space.minVotingDuration());

        _tryExecute(proposalId, executionStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.VotingPeriodAccepted));
    }

    function testOptimisticQuorumLotsOfVotes() public {
        // SET A QUORUM OF 100
        {
            quorum = 100;
            address optimisticQuorumStrategy2 = address(new OptimisticExec(spaceOwner, quorum));
            executionStrategy = Strategy(optimisticQuorumStrategy2, new bytes(0));
        }

        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        // Add 200 FOR votes
        for (uint160 i = 10; i < 210; i++) {
            _vote(address(i), proposalId, 1, userVotingStrategies, voteMetadataURI);
        }
        // Add 150 ABSTAIN votes
        for (uint160 i = 500; i < 650; i++) {
            _vote(address(i), proposalId, 2, userVotingStrategies, voteMetadataURI);
        }
        // Add 100 AGAINST votes
        for (uint160 i = 700; i < 800; i++) {
            _vote(address(i), proposalId, 0, userVotingStrategies, voteMetadataURI);
        }

        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, executionStrategy.params);
        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Executed));
    }

    function testOptimisticQuorumSetQuorum() public {
        uint256 newQuorum = quorum * 2; // 4

        vm.expectEmit(true, true, true, true);
        emit QuorumUpdated(newQuorum);
        optimisticQuorumStrategy.setQuorum(newQuorum);

        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));

        // Cast two votes against. This should be enough to trigger the old quorum but not the new one.
        _vote(author, proposalId, 0, userVotingStrategies, voteMetadataURI);
        _vote(address(42), proposalId, 0, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        // vm.expectEmit(true, true, true, true);
        // emit ProposalExecuted(proposalId);
        _tryExecute(proposalId, executionStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Accepted));
    }

    function testOptimisticQuorumSetQuorumUnauthorized() public {
        uint256 newQuorum = quorum * 2; // 4
        vm.prank(address(0xdeadbeef));
        _expectOnlyOwnerRevert(address(0xdeadbeef));
        optimisticQuorumStrategy.setQuorum(newQuorum);
    }
}
