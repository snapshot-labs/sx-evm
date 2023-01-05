// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Space.sol";
import "../src/types.sol";
import "forge-std/console2.sol";
import "../src/voting-strategies/VanillaVotingStrategy.sol";
import "../src/interfaces/ISpace.sol";
import "../src/interfaces/space/ISpaceEvents.sol";

contract SettersTest is Test, ISpaceEvents {
    ISpace public space;

    uint32 private votingDelay = 0;
    uint32 private minVotingDuration = 1;
    uint32 private maxVotingDuration = 1000;
    uint32 private proposalThreshold = 1;
    uint32 private quorum = 1;
    VotingStrategy[] private votingStrategies;
    address[] private authenticators = [address(this)];
    address[] private executionStrategies = [address(0)];
    bytes[] private userVotingStrategyParams = [new bytes(0)];
    bytes private executionParams = new bytes(0);
    address private owner = address(this);
    uint256[] private usedVotingStrategiesIndices = [0];

    string private metadataUri = "Snapshot On-Chain";

    function setUp() public {
        VanillaVotingStrategy vanillaVotingStrategy = new VanillaVotingStrategy();
        VotingStrategy memory votingStrategy = VotingStrategy(address(vanillaVotingStrategy), new bytes(0));
        votingStrategies.push(votingStrategy);

        Space spaceContract = new Space(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            authenticators,
            executionStrategies
        );
        space = ISpace(address(spaceContract));
    }

    // ------- MaxVotingDuration ----

    function testSetMaxVotingDuration() public {
        // Ensure event gets fired properly
        vm.expectEmit(true, true, true, true);
        uint32 nextDuration = maxVotingDuration + 1;
        emit MaxVotingDurationUpdated(maxVotingDuration, nextDuration);
        space.setMaxVotingDuration(nextDuration);

        uint32 duration = space.maxVotingDuration();
        require(duration == nextDuration, "Max Voting Duration did not get updated");
    }

    function testOwnerSetMaxVotingDelay() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));
        space.setMaxVotingDuration(2000);
    }

    function testSetInvalidMaxVotingDelay() public {
        vm.expectRevert("Max Duration must be bigger than Min Duration");
        space.setMaxVotingDuration(minVotingDuration - 1);
    }

    // ------- MinVotingDuration ----

    function testSetMinVotingDelay() public {
        // Ensure event gets fired properly
        vm.expectEmit(true, true, true, true);
        uint32 nextDuration = minVotingDuration + 1;
        emit MinVotingDurationUpdated(minVotingDuration, nextDuration);
        space.setMinVotingDuration(nextDuration);

        uint32 duration = space.minVotingDuration();
        require(duration == nextDuration, "Min Voting Duration did not get updated");
    }

    function testOwnerSetMinVotingDuration() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));
        space.setMinVotingDuration(2000);
    }

    function testOwnerSetMinVotingDelay() public {
        vm.expectRevert("Min Duration must be smaller than Max Duration");
        space.setMinVotingDuration(maxVotingDuration + 1);
    }

    // ------- MetadataUri ----

    function testSetMetadataUri() public {
        // Ensure event gets fired properly
        vm.expectEmit(true, true, true, true);
        string memory newMetadataUri = "All your bases are belong to us";
        emit MetadataUriUpdated(newMetadataUri);

        space.setMetadataUri(newMetadataUri);
    }

    function testOwnerSetMetadataUri() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.setMetadataUri("All your bases are belong to us");
    }

    // ------- ProposalThreshold ----

    function testSetProposalThreshold() public {
        uint256 nextThreshold = 2;

        // Ensure event gets fired properly
        vm.expectEmit(true, true, true, true);
        emit ProposalThresholdUpdated(proposalThreshold, nextThreshold);

        space.setProposalThreshold(nextThreshold);

        uint256 threshold = space.proposalThreshold();
        require(threshold == nextThreshold, "Proposal Threshold did not get updated");
    }

    function testOwnerSetProposalThreshold() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.setProposalThreshold(2);
    }

    // ------- Quorum ----

    function testSetQuorum() public {
        uint newQuorum = 2;

        // Ensure event gets fired properly
        vm.expectEmit(true, true, true, true);
        emit QuorumUpdated(quorum, newQuorum);

        space.setQuorum(newQuorum);

        uint256 q = space.quorum();
        require(q == newQuorum, "Quorum did not get updated");
    }

    function testOwnerSetQuorum() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));
        space.setQuorum(2);
    }

    // ------- VotingDelay ----

    function testSetVotingDelay() public {
        uint32 nextDelay = 10;

        // Ensure event gets fired properly
        vm.expectEmit(true, true, true, true);
        emit VotingDelayUpdated(votingDelay, nextDelay);
        space.setVotingDelay(nextDelay);

        uint32 delay = space.votingDelay();
        require(delay == nextDelay, "Voting Delay did not get updated");
    }

    function testOwnerSetVotingDelay() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));
        space.setVotingDelay(2);
    }

    // ------- VotingStrategies ----

    function testAddAndRemoveVotingStrategies() public {
        // Create a new array of voting strategy
        VotingStrategy[] memory newVotingStrategies = new VotingStrategy[](1);
        // This array contains the same voting strategy as the initial one but
        // should be accessed with a new strategy index.
        newVotingStrategies[0] = VotingStrategy(votingStrategies[0].addy, votingStrategies[0].params);

        // New strategy index should be `1` (`0` is used for the first one!).
        uint256[] memory newIndices = new uint256[](1);
        newIndices[0] = 1;

        uint256 nextNonce = space.nextProposalNonce();

        // Ensure event gets fired properly
        vm.expectEmit(true, true, true, true);
        emit VotingStrategiesAdded(newVotingStrategies);
        // Add the new voting Strategies
        space.addVotingStrategies(newVotingStrategies);

        // Ensure event gets fired properly.
        vm.expectEmit(true, false, false, false);
        // Empty proposal that won't actually get checked but just used to fire the event.
        Proposal memory tmpProposal;
        // Note: Here we don't check the content but simply that the event got fired.
        emit ProposalCreated(1, address(0), tmpProposal, metadataUri, executionParams);
        // Try creating a proposal using these new strategies.
        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            newIndices,
            userVotingStrategyParams,
            executionParams
        );

        // Ensure proposal exists (querying an invalid nonce will throw)
        // TODO: add test that throws if we query an invalid nonce
        space.getProposalInfo(nextNonce);

        // Ensure event gets fired properly
        vm.expectEmit(true, true, true, true);
        emit VotingStrategiesRemoved(newIndices);
        // Remove the voting strategies
        space.removeVotingStrategies(newIndices);

        // Try creating a proposal using these new strategies (should revert)
        vm.expectRevert("Invalid Voting Strategy Index");
        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            newIndices,
            userVotingStrategyParams,
            executionParams
        );

        // Ensure event gets fired properly.
        vm.expectEmit(true, false, false, false);
        // Note: Here we don't check the content but simply that the event got fired.
        emit ProposalCreated(1, address(0), tmpProposal, metadataUri, executionParams);

        // Try creating a proposal with the previous voting strategy
        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );

        // Ensure proposal exists
        space.getProposalInfo(nextNonce + 1);
    }

    function testOwnerAddVotingStrategies() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.addVotingStrategies(votingStrategies);
    }

    function testOwnerRemoveVotingStrategies() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.removeVotingStrategies(usedVotingStrategiesIndices);
    }

    // ------- Authenticators ----
    function testAddAndRemoveAuthenticator() public {
        address[] memory newAuths = new address[](1);
        newAuths[0] = address(42);

        // Ensure the event gets fired properly.
        vm.expectEmit(true, true, true, true);
        emit AuthenticatorsAdded(newAuths);

        // Add auths
        space.addAuthenticators(newAuths);

        // Ensure event gets fired properly.
        vm.expectEmit(true, false, false, false);
        Proposal memory tmpProposal;
        // Note: Here we don't check the content but simply that the event got fired.
        emit ProposalCreated(1, address(0), tmpProposal, metadataUri, executionParams);

        // Create a new proposal by using the new authenticator
        vm.prank(newAuths[0]);
        space.propose(
            address(1337),
            metadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );

        // Ensure the event gets fired properly.
        vm.expectEmit(true, true, true, true);
        emit AuthenticatorsRemoved(newAuths);

        // Remove the authenticator
        space.removeAuthenticators(newAuths);

        // Ensure we can't propose with this authenticator anymore
        vm.expectRevert("Invalid Authenticator");
        vm.prank(newAuths[0]);
        space.propose(
            address(1337),
            metadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );
    }

    function testOwnerAddAuthenticators() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.removeAuthenticators(authenticators);
    }

    function testOwnerRemoveAuthenticators() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.removeAuthenticators(authenticators);
    }

    // ------- ExecutionStrategies ----
    function testAddAndRemoveExecutionStrategies() public {
        address[] memory newStrats = new address[](1);
        newStrats[0] = address(42);
        Proposal memory tmpProposal;

        // Ensure event gets fired properly.
        vm.expectEmit(true, true, true, true);
        emit ExecutionStrategiesAdded(newStrats);

        // Add execution strategies
        space.addExecutionStrategies(newStrats);

        // Ensure event gets fired properly.
        vm.expectEmit(true, false, false, false);
        // Note: Here we don't check the content but simply that the event got fired.
        emit ProposalCreated(1, address(0), tmpProposal, metadataUri, executionParams);

        space.propose(
            address(1337),
            metadataUri,
            newStrats[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );

        // Ensure event gets fired properly.
        vm.expectEmit(true, true, true, true);
        emit ExecutionStrategiesRemoved(newStrats);

        // Add execution strategies
        space.removeExecutionStrategies(newStrats);

        // Try proposing with the removed execution Strategy. Should fail.
        vm.expectRevert("Invalid Execution Strategy");
        space.propose(
            address(1337),
            metadataUri,
            newStrats[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );
    }

    function testOwnerAddExecutionStrategy() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.removeExecutionStrategies(executionStrategies);
    }

    function testOwnerRemoveExecutionStrategy() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.removeExecutionStrategies(executionStrategies);
    }
}
