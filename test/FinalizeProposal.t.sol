// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./utils/Space.t.sol";
import "forge-std/Test.sol";
import "../src/SpaceErrors.sol";
import "../src/types.sol";

contract FinalizeProposalTest is SpaceTest {
    function createProposal() internal returns (uint256) {
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(author, proposalMetadataUri, executionStrategy, userVotingStrategies)
        );

        return space.nextProposalId() - 1;
    }

    function vote(uint256 _proposalId, Choice _choice, IndexedStrategy[] memory _userVotingStrategies) internal {
        vanillaAuthenticator.authenticate(
            address(space),
            VOTE_SELECTOR,
            abi.encode(author, _proposalId, _choice, _userVotingStrategies)
        );
    }

    function testFinalize() public {
        uint256 proposalId = createProposal();

        vote(proposalId, Choice.For, userVotingStrategies);

        // Check that the event gets fired correctly.
        vm.expectEmit(true, true, true, true);
        emit ProposalFinalized(proposalId, ProposalOutcome.Accepted);

        space.finalizeProposal(proposalId, executionStrategy.params);
    }

    function testFinalizeInvalidProposal() public {
        uint256 proposalId = createProposal();
        uint256 invalidProposalId = proposalId + 1;

        vote(proposalId, Choice.For, userVotingStrategies);

        vm.expectRevert(abi.encodeWithSelector(InvalidProposalId.selector, invalidProposalId));
        space.finalizeProposal(invalidProposalId, executionStrategy.params);
    }

    function testFinalizeProposalAlreadyExecuted() public {
        uint256 proposalId = createProposal();

        vote(proposalId, Choice.For, userVotingStrategies);
        space.finalizeProposal(proposalId, executionStrategy.params);

        vm.expectRevert(abi.encodeWithSelector(ProposalAlreadyExecuted.selector));
        space.finalizeProposal(proposalId, executionStrategy.params);
    }

    function testFinalizeMinDurationNotElapsed() public {
        space.setMinVotingDuration(100);

        uint256 proposalId = createProposal();

        vote(proposalId, Choice.For, userVotingStrategies);

        vm.expectRevert(abi.encodeWithSelector(MinVotingDurationHasNotElapsed.selector));
        space.finalizeProposal(proposalId, executionStrategy.params);

        // Ensure we can still finalize once min voting duration has elapsed.
        vm.warp(block.timestamp + space.minVotingDuration());
        space.finalizeProposal(proposalId, executionStrategy.params);
    }

    function testFinalizeExecutionMismatch() public {
        uint256 proposalId = createProposal();

        vote(proposalId, Choice.For, userVotingStrategies);

        vm.expectRevert(abi.encodeWithSelector(ExecutionHashMismatch.selector));
        space.finalizeProposal(proposalId, new bytes(4242));
    }

    function testFinalizeQuorumNotReachedYet() public {
        uint256 proposalId = createProposal();

        vm.expectRevert(abi.encodeWithSelector(QuorumNotReachedYet.selector));
        space.finalizeProposal(proposalId, executionStrategy.params);
    }

    function testFinalizeQuorumNotReachedAtAll() public {
        uint256 proposalId = createProposal();

        vm.warp(block.timestamp + space.maxVotingDuration());

        // Should finalize
        space.finalizeProposal(proposalId, executionStrategy.params);

        // Ensure proposal is `Rejected`.
        ProposalStatus status = space.getProposalStatus(proposalId);
        assertEq(uint8(status), uint8(ProposalStatus.Rejected));
    }

    function testFinalizeFor() public {
        uint256 proposalId = createProposal();
        vote(proposalId, Choice.For, userVotingStrategies);

        space.finalizeProposal(proposalId, executionStrategy.params);
        // Ensure proposal is `Accepted`.
        ProposalStatus status = space.getProposalStatus(proposalId);
        assertEq(uint8(status), uint8(ProposalStatus.Accepted));
    }

    function testFinalizeAgainst() public {
        uint256 proposalId = createProposal();
        vote(proposalId, Choice.Against, userVotingStrategies);

        space.finalizeProposal(proposalId, executionStrategy.params);
        // Ensure proposal is `Rejected`.
        ProposalStatus status = space.getProposalStatus(proposalId);
        assertEq(uint8(status), uint8(ProposalStatus.Rejected));
    }

    function testFinalizeAbstain() public {
        uint256 proposalId = createProposal();
        vote(proposalId, Choice.Abstain, userVotingStrategies);

        space.finalizeProposal(proposalId, executionStrategy.params);
        // Ensure proposal is `Rejected`.
        ProposalStatus status = space.getProposalStatus(proposalId);
        assertEq(uint8(status), uint8(ProposalStatus.Rejected));
    }
}
