// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { Choice, IndexedStrategy, Proposal, ProposalStatus, Strategy } from "../src/types.sol";
import { EmergencyQuorumStrategy } from "../src/execution-strategies/EmergencyQuorumStrategy.sol";

contract EmergencyQuorumExec is EmergencyQuorumStrategy {
    uint256 internal numExecuted;

    constructor(uint256 _quorum, uint256 _emergencyQuorum) EmergencyQuorumStrategy(_quorum, _emergencyQuorum) {}

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
    Strategy internal emergencyStrategy;
    uint256 internal emergencyQuorum = 2;
    EmergencyQuorumExec internal emergency;

    function setUp() public override {
        super.setUp();

        emergency = new EmergencyQuorumExec(quorum, emergencyQuorum);
        emergencyStrategy = Strategy(address(emergency), new bytes(0));

        minVotingDuration = 100;
        space.setMinVotingDuration(minVotingDuration); // Min voting duration of 100
    }

    function testEmergencyQuorum() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataURI); // 1
        _vote(address(42), proposalId, Choice.For, userVotingStrategies, voteMetadataURI); // 2

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        space.execute(proposalId, emergencyStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Executed));
    }

    function testEmergencyQuorumNotReached() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataURI); // 1

        vm.expectRevert(abi.encodeWithSelector(InvalidProposalStatus.selector, uint8(ProposalStatus.VotingPeriod)));
        space.execute(proposalId, emergencyStrategy.params);
    }

    function testEmergencyQuorumAfterMinDuration() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataURI); // 1

        vm.warp(block.timestamp + minVotingDuration);

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        space.execute(proposalId, emergencyStrategy.params);
    }

    function testEmergencyQuorumAfterMaxDuration() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataURI); // 1

        vm.warp(block.timestamp + maxVotingDuration);

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        space.execute(proposalId, emergencyStrategy.params);
    }

    function testEmergencyQuorumReachedButRejected() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.Against, userVotingStrategies, voteMetadataURI); // 1
        _vote(address(42), proposalId, Choice.Against, userVotingStrategies, voteMetadataURI); // 2

        vm.expectRevert(abi.encodeWithSelector(InvalidProposalStatus.selector, uint8(ProposalStatus.Rejected)));
        space.execute(proposalId, emergencyStrategy.params);
    }

    function testEmergencyLowerThanQuorum() public {
        EmergencyQuorumExec lowerThanQuorum = new EmergencyQuorumExec(quorum, quorum - 1);

        emergencyStrategy = Strategy(address(lowerThanQuorum), new bytes(0));

        // Create proposal and vote
        uint256 proposalId = _createProposal(author, proposalMetadataURI, emergencyStrategy, userVotingStrategies);
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataURI); // emergencyQuorum reached
        vm.warp(block.timestamp + maxVotingDuration);

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        space.execute(proposalId, emergencyStrategy.params);
    }
}
