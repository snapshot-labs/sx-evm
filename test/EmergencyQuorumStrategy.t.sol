// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { Choice, IndexedStrategy, Proposal, ProposalStatus, Strategy } from "../src/types.sol";
import { EmergencyQuorumStrategy } from "../src/execution-strategies/EmergencyQuorumStrategy.sol";

contract EmergencyQuorumExec is EmergencyQuorumStrategy {
    uint256 internal numExecuted;

    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external override {
        ProposalStatus proposalStatus = getProposalStatus(proposal, votesFor, votesAgainst, votesAbstain);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }
        // Check that the execution payload matches the payload supplied when the proposal was created
        if (proposal.executionPayloadHash != keccak256(payload)) revert InvalidPayload();
        numExecuted++;
    }

    function getStrategyType() external pure returns (string memory) {
        return "EmergencyQuorumExecution";
    }
}

contract EmergencyQuorumTest is SpaceTest {
    IndexedStrategy internal emergencyStrategy;
    uint256 internal emergencyQuorum = 2;
    EmergencyQuorumExec internal emergency;

    function setUp() public override {
        super.setUp();

        emergency = new EmergencyQuorumExec();
        Strategy[] memory toAdd = new Strategy[](1);
        toAdd[0] = Strategy(address(emergency), abi.encode(quorum, emergencyQuorum));
        space.addExecutionStrategies(toAdd);

        emergencyStrategy = IndexedStrategy(1, new bytes(0));

        uint8[] memory toRemove = new uint8[](1);
        toRemove[0] = 0;
        space.removeExecutionStrategies(toRemove);

        minVotingDuration = 100;
        space.setMinVotingDuration(minVotingDuration); // Min voting duration of 100
    }

    function testEmergencyQuorum() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri); // 1
        _vote(address(42), proposalId, Choice.For, userVotingStrategies, voteMetadataUri); // 2

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        space.execute(proposalId, emergencyStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Executed));
    }

    function testEmergencyQuorumNotReached() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri); // 1

        vm.expectRevert(abi.encodeWithSelector(InvalidProposalStatus.selector, uint8(ProposalStatus.VotingPeriod)));
        space.execute(proposalId, emergencyStrategy.params);
    }

    function testEmergencyQuorumAfterMinDuration() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri); // 1

        vm.warp(block.timestamp + minVotingDuration);

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        space.execute(proposalId, emergencyStrategy.params);
    }

    function testEmergencyQuorumAfterMaxDuration() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri); // 1

        vm.warp(block.timestamp + maxVotingDuration);

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        space.execute(proposalId, emergencyStrategy.params);
    }

    function testEmergencyQuorumReachedButRejected() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.Against, userVotingStrategies, voteMetadataUri); // 1
        _vote(address(42), proposalId, Choice.Against, userVotingStrategies, voteMetadataUri); // 2

        vm.expectRevert(abi.encodeWithSelector(InvalidProposalStatus.selector, uint8(ProposalStatus.Rejected)));
        space.execute(proposalId, emergencyStrategy.params);
    }

    function testEmergencyLowerThanQuorum() public {
        // Add a new execution strategy
        Strategy[] memory toAdd = new Strategy[](1);
        toAdd[0] = Strategy(address(emergency), abi.encode(quorum + 1, quorum));

        space.addExecutionStrategies(toAdd);

        emergencyStrategy = IndexedStrategy(2, new bytes(0));
        uint8[] memory toRemove = new uint8[](1);
        toRemove[0] = 1;
        space.removeExecutionStrategies(toRemove);

        // Create proposal and vote
        uint256 proposalId = _createProposal(author, proposalMetadataUri, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri); // emergencyQuorum reached
        vm.warp(block.timestamp + maxVotingDuration);

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        space.execute(proposalId, emergencyStrategy.params);
    }
}
