// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "./Space.t.sol";
import "../src/Space.sol";
import "../src/types.sol";
import "forge-std/console2.sol";
import "../src/voting-strategies/VanillaVotingStrategy.sol";
import "../src/interfaces/ISpace.sol";
import "../src/interfaces/space/ISpaceEvents.sol";

contract SpaceOwnerActionsTest is SpaceTest {
    // ------- MaxVotingDuration ----

    function testSetMaxVotingDuration() public {
        vm.expectEmit(true, true, true, true);
        uint32 nextDuration = maxVotingDuration + 1;
        emit MaxVotingDurationUpdated(maxVotingDuration, nextDuration);
        vm.prank(owner);
        space.setMaxVotingDuration(nextDuration);

        assertEq(space.maxVotingDuration(), nextDuration, "Max Voting Duration did not get updated");
    }

    function testUnauthorizedSetMaxVotingDelay() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.setMaxVotingDuration(2000);
    }

    function testSetInvalidMaxVotingDelay() public {
        vm.expectRevert("Max Duration must be bigger than Min Duration");
        vm.prank(owner);
        space.setMaxVotingDuration(minVotingDuration - 1);
    }

    // ------- MinVotingDuration ----

    function testSetMinVotingDelay() public {
        vm.expectEmit(true, true, true, true);
        uint32 nextDuration = minVotingDuration + 1;
        emit MinVotingDurationUpdated(minVotingDuration, nextDuration);
        vm.prank(owner);
        space.setMinVotingDuration(nextDuration);

        assertEq(space.minVotingDuration(), nextDuration, "Min Voting Duration did not get updated");
    }

    function testUnauthorizedSetMinVotingDuration() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.setMinVotingDuration(2000);
    }

    function testSetInvalidMinVotingDelay() public {
        vm.expectRevert("Min Duration must be smaller than Max Duration");
        vm.prank(owner);
        space.setMinVotingDuration(maxVotingDuration + 1);
    }

    // ------- MetadataUri ----

    function testSetMetadataUri() public {
        string memory newMetadataUri = "All your bases are belong to us";
        vm.expectEmit(true, true, true, true);
        emit MetadataUriUpdated(newMetadataUri);
        space.setMetadataUri(newMetadataUri);

        // Metadata Uri is not stored in the contract state so we can't check it
    }

    function testUnauthorizedSetMetadataUri() public {
        string memory newMetadataUri = "All your bases are belong to us";
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.setMetadataUri(newMetadataUri);
    }

    // ------- ProposalThreshold ----

    function testSetProposalThreshold() public {
        uint256 nextThreshold = 2;
        vm.expectEmit(true, true, true, true);
        emit ProposalThresholdUpdated(proposalThreshold, nextThreshold);
        vm.prank(owner);
        space.setProposalThreshold(nextThreshold);

        assertEq(space.proposalThreshold(), nextThreshold, "Proposal Threshold did not get updated");
    }

    function testUnauthorizedSetProposalThreshold() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.setProposalThreshold(2);
    }

    // ------- Quorum ----

    function testSetQuorum() public {
        uint256 newQuorum = 2;
        vm.expectEmit(true, true, true, true);
        emit QuorumUpdated(quorum, newQuorum);
        vm.prank(owner);
        space.setQuorum(newQuorum);

        assertEq(space.quorum(), newQuorum, "Quorum did not get updated");
    }

    function testUnauthorizedSetQuorum() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.setQuorum(2);
    }

    // ------- VotingDelay ----

    function testSetVotingDelay() public {
        uint32 nextDelay = 10;
        vm.expectEmit(true, true, true, true);
        emit VotingDelayUpdated(votingDelay, nextDelay);
        vm.prank(owner);
        space.setVotingDelay(nextDelay);

        assertEq(space.votingDelay(), nextDelay, "Voting Delay did not get updated");
    }

    function testUnauthorizedSetVotingDelay() public {
        uint32 nextDelay = 10;
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.setVotingDelay(nextDelay);
    }

    // ------- VotingStrategies ----

    function testAddAndRemoveVotingStrategies() public {
        // This voting strategy array contains the same voting strategy as the initial one but
        // should be accessed with a new strategy index.
        VotingStrategy[] memory newVotingStrategies = new VotingStrategy[](1);
        newVotingStrategies[0] = VotingStrategy(votingStrategies[0].addy, votingStrategies[0].params);

        // New strategy index should be `1` (`0` is used for the first one).
        uint256[] memory newIndices = new uint256[](1);
        newIndices[0] = 1;

        vm.expectEmit(true, true, true, true);
        emit VotingStrategiesAdded(newVotingStrategies);
        vm.prank(owner);
        space.addVotingStrategies(newVotingStrategies);

        // Try creating a proposal using these new strategies.
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(
                author,
                proposalMetadataUri,
                executionStrategies[0],
                newIndices,
                userVotingStrategyParams,
                executionParams
            )
        );

        // Remove the voting strategies
        vm.expectEmit(true, true, true, true);
        emit VotingStrategiesRemoved(newIndices);
        space.removeVotingStrategies(newIndices);

        // Try creating a proposal using these strategies that were just removed.
        vm.expectRevert("Invalid Voting Strategy Index");
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(
                author,
                proposalMetadataUri,
                executionStrategies[0],
                newIndices,
                userVotingStrategyParams,
                executionParams
            )
        );

        // Try creating a proposal with the previous voting strategy that was never removed.
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
    }

    function testUnauthorizedAddVotingStrategies() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.addVotingStrategies(votingStrategies);
    }

    function testUnauthorizedRemoveVotingStrategies() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.removeVotingStrategies(usedVotingStrategiesIndices);
    }

    // ------- Authenticators ----
    function testAddAndRemoveAuthenticator() public {
        address[] memory newAuths = new address[](1);

        // Using this test contract as a mock authenticator
        newAuths[0] = address(this);

        vm.expectEmit(true, true, true, true);
        emit AuthenticatorsAdded(newAuths);
        space.addAuthenticators(newAuths);

        // The new authenticator is this contract so we can call `propose` directly.
        space.propose(
            author,
            proposalMetadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );

        vm.expectEmit(true, true, true, true);
        emit AuthenticatorsRemoved(newAuths);
        space.removeAuthenticators(newAuths);

        // Ensure we can't propose with this authenticator anymore
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

    function testUnauthorizedAddAuthenticators() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.removeAuthenticators(authenticators);
    }

    function testUnauthorizedRemoveAuthenticators() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.removeAuthenticators(authenticators);
    }

    // ------- ExecutionStrategies ----

    function testAddAndRemoveExecutionStrategies() public {
        // TODO: test finalizeProposal here once we have it

        address[] memory newExecutionStrategies = new address[](1);
        newExecutionStrategies[0] = address(42); // Random address

        vm.expectEmit(true, true, true, true);
        emit ExecutionStrategiesAdded(newExecutionStrategies);
        space.addExecutionStrategies(newExecutionStrategies);

        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(
                author,
                proposalMetadataUri,
                newExecutionStrategies[0],
                usedVotingStrategiesIndices,
                userVotingStrategyParams,
                executionParams
            )
        );

        vm.expectEmit(true, true, true, true);
        emit ExecutionStrategiesRemoved(newExecutionStrategies);
        space.removeExecutionStrategies(newExecutionStrategies);

        // Ensure we cant propose with this execution strategy anymore
        vm.expectRevert("Invalid Execution Strategy");

        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(
                author,
                proposalMetadataUri,
                newExecutionStrategies[0],
                usedVotingStrategiesIndices,
                userVotingStrategyParams,
                executionParams
            )
        );
    }

    function testunauthorizedAddExecutionStrategy() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.removeExecutionStrategies(executionStrategies);
    }

    function testUnauthorizedRemoveExecutionStrategy() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(unauthorized);
        space.removeExecutionStrategies(executionStrategies);
    }
}