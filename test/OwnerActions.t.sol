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
    address[] private votingStrategies;
    bytes[] private votingStrategiesParams;
    address[] private authenticators = [address(this)];
    address[] private executionStrategies = [address(0)];
    bytes[] private userVotingStrategyParams = [new bytes(0)];
    bytes private executionParams = new bytes(0);
    address private owner = address(this);
    uint256[] private usedVotingStrategiesIndices = [0];

    string private metadataUri = "Snapshot On-Chain";

    // TODO: add setters and test them (maybe in another test file)
    function setUp() public {
        VanillaVotingStrategy vanillaVotingStrategy = new VanillaVotingStrategy();
        votingStrategies.push(address(vanillaVotingStrategy));
        votingStrategiesParams.push(new bytes(0));

        Space spaceContract = new Space(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            votingStrategiesParams,
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
        address[] memory newVotingStrategies = new address[](1);
        newVotingStrategies[0] = votingStrategies[0];
        bytes[] memory newVotingStrategiesParams = new bytes[](1);
        newVotingStrategiesParams[0] = votingStrategiesParams[0];

        uint256[] memory newIndices = new uint256[](1);
        newIndices[0] = 1;

        uint256 nextNonce = space.nextProposalNonce();

        // Ensure event gets fired properly
        vm.expectEmit(true, true, true, true);
        emit VotingStrategiesAdded(newVotingStrategies, newVotingStrategiesParams);
        // Add the new voting Strategies
        space.addVotingStrategies(newVotingStrategies, newVotingStrategiesParams);

        // Ensure event gets fired properly.
        vm.expectEmit(true, false, false, false);
        // Empty proposal that won't actually get checked but just used to fire the event.
        Proposal memory proposal;
        // Note: Here we don't check the content but simply that the event got fired.
        emit ProposalCreated(1, address(0), proposal, metadataUri, executionParams);
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
        emit ProposalCreated(1, address(0), proposal, metadataUri, executionParams);

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

        space.addVotingStrategies(votingStrategies, votingStrategiesParams);
    }

    function testOwnerRemoveVotingStrategies() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.removeVotingStrategies(usedVotingStrategiesIndices);
    }

    // ------- Authenticators ----
    // ------- ExecutionStrategies ----
}
