// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/Space.sol";
import "../src/types.sol";
import "../src/voting-strategies/VanillaVotingStrategy.sol";
import "../src/interfaces/space/ISpaceEvents.sol";
import { GasSnapshot } from "forge-gas-snapshot/GasSnapshot.sol";

contract SpaceActionsTest is Test, ISpaceEvents, GasSnapshot {
    Space public space;

    uint32 private votingDelay = 0;
    uint32 private minVotingDuration = 0;
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
        VotingStrategy memory vanillaStrategy = VotingStrategy(address(vanillaVotingStrategy), new bytes(0));
        votingStrategies.push(vanillaStrategy);
        snapStart("CreateSpace");
        space = new Space(
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
        snapEnd();
    }

    function testInvalidAuth() public {
        // Sender will not be a whiteslisted auth
        vm.prank(address(0));

        // Expect revert
        vm.expectRevert("Invalid Authenticator");

        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );
    }

    function testInvalidExecutionStrategy() public {
        address invalidExecutionStrategy = address(1);

        // Expect revert
        vm.expectRevert("Invalid Execution Strategy");

        space.propose(
            address(this),
            metadataUri,
            invalidExecutionStrategy,
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );
    }

    function testInvalidUsedVotingStrategy() public {
        uint256[] memory invalidUsedStrategy = new uint256[](1);
        invalidUsedStrategy[0] = 42;

        // Expect revert (out of bounds).
        vm.expectRevert();

        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            invalidUsedStrategy,
            userVotingStrategyParams,
            executionParams
        );
    }

    function testDuplicateUsedVotingStrategy() public {
        uint256[] memory invalidUsedStrategy = new uint256[](4);
        invalidUsedStrategy[0] = 0;
        invalidUsedStrategy[0] = 1;
        invalidUsedStrategy[0] = 2;
        invalidUsedStrategy[0] = 0; // Duplicate entry

        bytes[] memory _userVotingStrategyParams = new bytes[](4);
        _userVotingStrategyParams[0] = new bytes(0);
        _userVotingStrategyParams[1] = new bytes(0);
        _userVotingStrategyParams[2] = new bytes(0);
        _userVotingStrategyParams[3] = new bytes(0);

        // Expect revert
        vm.expectRevert("Duplicates found");

        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            invalidUsedStrategy,
            _userVotingStrategyParams,
            executionParams
        );
    }

    function testValidProposal() public {
        vm.expectEmit(true, false, false, false);
        // Placeholder variable just to check that the event got fired
        Proposal memory tmp;
        // We will only check that the event is fired, not the actual content.
        // The reason for that is that we can't know the exact timestamp so the `proposal` struct
        // will probably be incorrect. We check fields individually after anyway so it shouldn't matter.
        emit ProposalCreated(1, address(this), tmp, metadataUri, executionParams);

        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );

        Proposal memory proposal = space.getProposalInfo(1);
        assertEq(proposal.quorum, quorum, "Quorum not set properly");
        assertEq(proposal.snapshotTimestamp + votingDelay, proposal.startTimestamp, "StartTimestamp not set properly");
        assertEq(
            proposal.startTimestamp + minVotingDuration,
            proposal.minEndTimestamp,
            "MinEndTimestamp not set properly"
        );
        assertEq(
            proposal.startTimestamp + maxVotingDuration,
            proposal.maxEndTimestamp,
            "MaxEndTimestamp not set properly"
        );
        assertEq(proposal.executionStrategy, executionStrategies[0], "ExecutionStrategy not set properly");

        bytes32 executionHash = keccak256(abi.encodePacked(executionParams));
        assertEq(proposal.executionHash, executionHash, "Execution Hash not computed properly");
    }

    function testGetInvalidProposalInfo() public {
        vm.expectRevert("Invalid proposalId");
        space.getProposalInfo(1337);
    }
}
