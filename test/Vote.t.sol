// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./utils/Space.t.sol";
import "forge-std/Test.sol";

contract VoteTest is SpaceTest {
    function createProposal() internal {
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(author, proposalMetadataUri, executionStrategy, userVotingStrategies)
        );
    }

    function testVote() public {
        createProposal();

        uint256 proposalId = space.nextProposalId() - 1;

        vanillaAuthenticator.authenticate(
            address(space),
            VOTE_SELECTOR,
            abi.encode(author, proposalId, Choice.For, userVotingStrategies)
        );

        // Advance timestamp
        vm.warp(block.timestamp + space.minVotingDuration());

        // Check that the event gets fired correctly.
        vm.expectEmit(true, true, true, true);
        emit ProposalFinalized(proposalId, ProposalOutcome.Accepted);

        space.finalizeProposal(proposalId, executionStrategy.params);
    }
}
