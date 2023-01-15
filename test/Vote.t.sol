// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./Space.t.sol";
import "forge-std/Test.sol";
import "../src/SpaceErrors.sol";
import "../src/types.sol";

contract VoteTest is SpaceTest {
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

    function testVote() public {
        uint256 proposalId = createProposal();

        vm.expectEmit(true, true, true, true);
        emit VoteCreated(proposalId, author, Vote(Choice.For, 1));
        vanillaAuthenticator.authenticate(
            address(space),
            VOTE_SELECTOR,
            abi.encode(author, proposalId, Choice.For, userVotingStrategies)
        );
    }

    function testVoteInvalidAuth() public {
        uint256 proposalId = createProposal();

        vm.expectRevert(abi.encodeWithSelector(AuthenticatorNotWhitelisted.selector, address(this)));
        space.vote(author, proposalId, Choice.For, userVotingStrategies);
    }

    function testVoteInvalidProposalId() public {
        uint256 proposalId = createProposal();
        uint256 invalidProposalId = proposalId + 1;

        vm.expectRevert(abi.encodeWithSelector(InvalidProposalId.selector, invalidProposalId));
        vote(invalidProposalId, Choice.For, userVotingStrategies);
    }

    function testVoteAlreadyExecuted() public {
        uint256 proposalId = createProposal();

        vote(proposalId, Choice.For, userVotingStrategies);

        space.finalizeProposal(proposalId, executionStrategy.params);

        vm.expectRevert(abi.encodeWithSelector(ProposalAlreadyExecuted.selector));
        vote(proposalId, Choice.For, userVotingStrategies);
    }

    function testVoteVotingPeriodHasEnded() public {
        uint256 proposalId = createProposal();

        vm.warp(block.timestamp + space.maxVotingDuration());
        vm.expectRevert(abi.encodeWithSelector(VotingPeriodHasEnded.selector));
        vote(proposalId, Choice.For, userVotingStrategies);
    }

    function testVoteVotingPeriodHasNotStarted() public {
        space.setVotingDelay(100);
        uint256 proposalId = createProposal();

        vm.expectRevert(abi.encodeWithSelector(VotingPeriodHasNotStarted.selector));
        vote(proposalId, Choice.For, userVotingStrategies);

        vm.warp(block.timestamp + space.votingDelay());
        vote(proposalId, Choice.For, userVotingStrategies);
    }

    function testVoteDoublevote() public {
        uint256 proposalId = createProposal();

        vote(proposalId, Choice.For, userVotingStrategies);

        vm.expectRevert(abi.encodeWithSelector(UserHasAlreadyVoted.selector));
        vote(proposalId, Choice.For, userVotingStrategies);
    }

    function testVoteNoVotingPower() public {
        uint256 proposalId = createProposal();

        IndexedStrategy[] memory empty = new IndexedStrategy[](0);

        vm.expectRevert(abi.encodeWithSelector(UserHasNoVotingPower.selector));
        vote(proposalId, Choice.For, empty);
    }

    function testVoteDuplicateStrategies() public {
        uint256 proposalId = createProposal();

        IndexedStrategy[] memory duplicateStrategies = new IndexedStrategy[](2);
        duplicateStrategies[0] = userVotingStrategies[0];
        duplicateStrategies[1] = userVotingStrategies[0];
        vm.expectRevert(
            abi.encodeWithSelector(DuplicateFound.selector, duplicateStrategies[0].index, duplicateStrategies[1].index)
        );
        vote(proposalId, Choice.For, duplicateStrategies);
    }

    function testVoteInvalidStrategies() public {
        uint256 proposalId = createProposal();

        IndexedStrategy[] memory invalidStrategies = new IndexedStrategy[](1);
        invalidStrategies[0] = IndexedStrategy(42, new bytes(0));

        vm.expectRevert();
        vote(proposalId, Choice.For, invalidStrategies);
    }
}
