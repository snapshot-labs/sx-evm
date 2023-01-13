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

contract SpaceActionsTest is SpaceTest {
    function testPropose() public {
        uint256 proposalId = space.nextProposalId();

        bytes32 executionHash = keccak256(abi.encodePacked(executionParams));
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
            executionStrategies[0],
            executionHash
        );

        vm.expectEmit(true, true, true, true);
        emit ProposalCreated(proposalId, author, proposal, proposalMetadataUri, executionParams);
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(
                author,
                proposalMetadataUri,
                executionStrategies[0],
                usedVotingStrategiesIndices,
                userVotingStrategyParams,
                executionParams
            )
        );

        // Actual content of the proposal struct
        Proposal memory _proposal = space.getProposalInfo(proposalId);

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
        vm.expectRevert("Invalid Authenticator");
        space.propose(
            author,
            proposalMetadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );
    }

    function testProposeInvalidExecutionStrategy() public {
        address invalidExecutionStrategy = address(1);
        vm.expectRevert("Invalid Execution Strategy");
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(
                author,
                proposalMetadataUri,
                invalidExecutionStrategy,
                usedVotingStrategiesIndices,
                userVotingStrategyParams,
                executionParams
            )
        );
    }

    function testProposeInvalidUsedVotingStrategy() public {
        uint256[] memory invalidUsedStrategy = new uint256[](1);
        invalidUsedStrategy[0] = 42;

        // out of bounds revert
        vm.expectRevert();
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(
                author,
                proposalMetadataUri,
                executionStrategies[0],
                invalidUsedStrategy,
                userVotingStrategyParams,
                executionParams
            )
        );
    }

    function testProposeDuplicateUsedVotingStrategy() public {
        uint256[] memory invalidUsedStrategy = new uint256[](4);
        invalidUsedStrategy[0] = 0;
        invalidUsedStrategy[0] = 1;
        invalidUsedStrategy[0] = 2;
        invalidUsedStrategy[0] = 0; // Duplicate entry

        bytes[] memory userVotingStrategyParams2 = new bytes[](4);
        userVotingStrategyParams2[0] = new bytes(0);
        userVotingStrategyParams2[1] = new bytes(0);
        userVotingStrategyParams2[2] = new bytes(0);
        userVotingStrategyParams2[3] = new bytes(0);

        vm.expectRevert("Duplicates found");
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(
                author,
                proposalMetadataUri,
                executionStrategies[0],
                invalidUsedStrategy,
                userVotingStrategyParams2,
                executionParams
            )
        );
    }

    function testGetInvalidProposalInfo() public {
        vm.expectRevert("Invalid proposalId");
        // No proposal has been created yet
        space.getProposalInfo(1);
    }
}
