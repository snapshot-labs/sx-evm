// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "./Space.t.sol";
import "forge-std/console2.sol";
import "../src/Space.sol";
import "../src/types.sol";
import "../src/voting-strategies/VanillaVotingStrategy.sol";
import "../src/interfaces/space/ISpaceEvents.sol";
import { GasSnapshot } from "forge-gas-snapshot/GasSnapshot.sol";

contract SpaceActionsTest is SpaceTest, SpaceErrors {
    function testPropose() public {
        uint256 proposalId = space.nextProposalId();

        bytes32 executionHash = keccak256(abi.encodePacked(executionStrategy.params));
        uint32 snapshotTimestamp = uint32(block.timestamp);
        uint32 startTimestamp = uint32(snapshotTimestamp + votingDelay);
        uint32 minEndTimestamp = uint32(startTimestamp + minVotingDuration);
        uint32 maxEndTimestamp = uint32(startTimestamp + maxVotingDuration);

        // Expected content of the proposal struct
        Proposal memory proposal = Proposal(
            quorum,
            snapshotTimestamp,
            startTimestamp,
            minEndTimestamp,
            maxEndTimestamp,
            executionStrategy.addy,
            executionHash
        );

        vm.expectEmit(true, true, true, true);
        emit ProposalCreated(proposalId, author, proposal, proposalMetadataUri, executionStrategy.params);
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(author, proposalMetadataUri, executionStrategy, userVotingStrategies)
        );

        // Actual content of the proposal struct
        Proposal memory _proposal = space.getProposal(proposalId);

        // Checking expectations and actual values match
        assertEq(_proposal.quorum, proposal.quorum, "Quorum not set properly");
        assertEq(_proposal.startTimestamp, proposal.startTimestamp, "StartTimestamp not set properly");
        assertEq(_proposal.minEndTimestamp, proposal.minEndTimestamp, "MinEndTimestamp not set properly");
        assertEq(_proposal.maxEndTimestamp, proposal.maxEndTimestamp, "MaxEndTimestamp not set properly");
        assertEq(_proposal.executionStrategy, proposal.executionStrategy, "ExecutionStrategy not set properly");
        assertEq(_proposal.executionHash, proposal.executionHash, "Execution Hash not computed properly");
    }

    function testProposeInvalidAuth() public {
        //  Using this contract as an authenticator, which is not whitelisted
        vm.expectRevert(abi.encodeWithSelector(AuthenticatorNotWhitelisted.selector, address(this)));
        space.propose(author, proposalMetadataUri, executionStrategy, userVotingStrategies);
    }

    function testProposeInvalidExecutionStrategy() public {
        Strategy[] memory invalidExecutionStrategy = new Strategy[](1);
        invalidExecutionStrategy[0] = Strategy(address(1), new bytes(0));
        vm.expectRevert(abi.encodeWithSelector(ExecutionStrategyNotWhitelisted.selector, address(1)));
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(author, proposalMetadataUri, invalidExecutionStrategy, userVotingStrategies)
        );
    }

    function testProposeInvalidUsedVotingStrategy() public {
        IndexedStrategy[] memory invalidUsedStrategies = new IndexedStrategy[](1);
        invalidUsedStrategies[0] = IndexedStrategy(42, new bytes(0));

        // out of bounds revert
        vm.expectRevert();
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(author, proposalMetadataUri, executionStrategy, invalidUsedStrategies)
        );
    }

    function testProposeDuplicateUserVotingStrategy() public {
        IndexedStrategy[] memory invalidUsedStrategies = new IndexedStrategy[](4);
        invalidUsedStrategies[0] = IndexedStrategy(0, new bytes(0));
        invalidUsedStrategies[1] = IndexedStrategy(1, new bytes(0));
        invalidUsedStrategies[2] = IndexedStrategy(2, new bytes(0));
        invalidUsedStrategies[3] = IndexedStrategy(0, new bytes(0)); // Duplicate index

        vm.expectRevert(abi.encodeWithSelector(DuplicateFound.selector, 0, 0));
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(author, proposalMetadataUri, executionStrategy, invalidUsedStrategies)
        );
    }
}