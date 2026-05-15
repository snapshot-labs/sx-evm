// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { IndexedStrategy, ProposalStatus, Strategy } from "../src/types.sol";
import { VanillaExecutionStrategy } from "../src/execution-strategies/VanillaExecutionStrategy.sol";

contract SimpleQuorumTest is SpaceTest {
    event QuorumUpdated(uint256 newQuorum);

    function test_SimpleQuorumSetQuorum() public {
        uint256 newQuorum = quorum * 2;
        vm.expectEmit(true, true, true, true);
        emit QuorumUpdated(newQuorum);
        vanillaExecutionStrategy.setQuorum(newQuorum);

        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));

        vm.warp(vm.getBlockTimestamp() + space.minVotingDuration());

        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI); // 1

        // Old quorum would've been reached here but not the new one.
        // tryExecute no longer reverts for a non-accepted proposal; it simply does not execute.
        _tryExecute(proposalId, executionStrategy.params);
        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.VotingPeriod));

        _vote(address(11), proposalId, 1, userVotingStrategies, voteMetadataURI); // 2

        // New quorum has been reached; proposal should be execute properly.
        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        _tryExecute(proposalId, executionStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Executed));
    }

    function test_SimpleQuorumSetQuorumUnauthorized() public {
        uint256 newQuorum = quorum * 2;
        vm.prank(address(0xdeadbeef));
        _expectOnlyOwnerRevert(address(0xdeadbeef));
        vanillaExecutionStrategy.setQuorum(newQuorum);
    }
}
