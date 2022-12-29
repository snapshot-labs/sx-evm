// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Space.sol";
import "forge-std/console2.sol";
import "../src/voting-strategies/VanillaVotingStrategy.sol";
import "../src/interfaces/ISpace.sol";

contract SettersTest is Test {
    ISpace public space;

    uint32 private votingDelay = 0;
    uint32 private minVotingDuration = 0;
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

    function testSetQuorum() public {
        space.setQuorum(2);
        // TODO: check event

        // TODO: Ensure new quorum is prevents user from finalizing a proposal

        // Reset quorum to initial value
        space.setQuorum(quorum);
    }

    function testOwnerSetQuorum() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));
        space.setQuorum(2);
    }

    function testSetProposalThreshold() public {
        space.setProposalThreshold(2);
        // TODO: check event

        vm.expectRevert("Proposal threshold not reached");

        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );

        space.setProposalThreshold(proposalThreshold);
    }

    function testOwnerSetProposalThreshold() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.setProposalThreshold(2);
    }

    function testSetMetadataUri() public {
        space.setMetadataUri("All your bases are belong to us");

        // TODO: check event
    }

    function testOwnerSetMetadataUri() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(address(1));

        space.setMetadataUri("All your bases are belong to us");
    }

    function testAddAndRemoveVotingStrategies() public {
        address[] memory newVotingStrategies = new address[](1);
        newVotingStrategies[0] = votingStrategies[0];
        bytes[] memory newVotingStrategiesParams = new bytes[](1);
        newVotingStrategiesParams[0] = votingStrategiesParams[0];

        uint256[] memory newIndices = new uint256[](1);
        newIndices[0] = 1;

        // Add the new voting Strategies
        space.addVotingStrategies(newVotingStrategies, newVotingStrategiesParams);
        // TODO: check event

        // Try creating a proposal using these new strategies.
        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            newIndices,
            userVotingStrategyParams,
            executionParams
        );

        // TODO: check event propose
        // tODO: check proposal exists

        // Remove the voting strategies
        space.removeVotingStrategies(newIndices);
        // TODO: check event

        vm.expectRevert("Invalid Voting Strategy Index");

        // Try creating a proposal using these new strategies (should revert)
        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            newIndices,
            userVotingStrategyParams,
            executionParams
        );

        // Try creating a proposal with the previous voting strategy
        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );

        // TODO: check event propose
        // TODO: check proposal exists
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
}
