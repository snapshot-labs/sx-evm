// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./utils/Space.t.sol";
import "forge-std/Test.sol";
import "../src/SpaceErrors.sol";
import "../src/types.sol";

contract GetCumulativePowerTest is SpaceTest {
    function testCumulativeThreeStrategies() public {
        VanillaVotingStrategy strat2 = new VanillaVotingStrategy();
        VanillaVotingStrategy strat3 = new VanillaVotingStrategy();
        Strategy[] memory toAdd = new Strategy[](2);
        toAdd[0] = Strategy(address(strat2), new bytes(0));
        toAdd[1] = Strategy(address(strat2), new bytes(0));

        space.addVotingStrategies(toAdd);

        uint256 proposalId = _createProposal(author, proposalMetadataUri, executionStrategy, userVotingStrategies);

        IndexedStrategy[] memory newVotingStrategies = new IndexedStrategy[](3);
        newVotingStrategies[0] = userVotingStrategies[0]; // base strat
        newVotingStrategies[1] = IndexedStrategy(1, new bytes(0)); // strat2
        newVotingStrategies[2] = IndexedStrategy(2, new bytes(0)); // strat3

        uint256 expectedVotingPower = 3; // 1 voting power per vanilla strat, so 3
        vm.expectEmit(true, true, true, true);
        emit VoteCreated(proposalId, author, Vote(Choice.For, expectedVotingPower));
        _vote(author, proposalId, Choice.For, newVotingStrategies);
    }

    function testCumulativeAddSameStrategyTwice() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, executionStrategy, userVotingStrategies);

        space.addVotingStrategies(votingStrategies); // Adding an already existing voting strategy. This is allowed.

        IndexedStrategy[] memory newVotingStrategies = new IndexedStrategy[](2);
        newVotingStrategies[0] = userVotingStrategies[0]; // base strat
        newVotingStrategies[1] = IndexedStrategy(1, new bytes(0)); // base strat again

        uint256 expectedVotingPower = 2; // 1 voting power per vanilla strat, so 2
        vm.expectEmit(true, true, true, true);
        emit VoteCreated(proposalId, author, Vote(Choice.For, expectedVotingPower));
        _vote(author, proposalId, Choice.For, newVotingStrategies);
    }

    function testCumulativeRemovedStrategy() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, executionStrategy, userVotingStrategies);

        uint8[] memory toRemove = new uint8[](1);
        toRemove[0] = userVotingStrategies[0].index;
        space.removeVotingStrategies(toRemove);

        vm.expectRevert();
        _vote(author, proposalId, Choice.For, userVotingStrategies); // Should revert because strategy has been removed
    }

    function testCumulativeDuplicate() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, executionStrategy, userVotingStrategies);

        IndexedStrategy[] memory duplicateStrategies = new IndexedStrategy[](2);
        duplicateStrategies[0] = userVotingStrategies[0];
        duplicateStrategies[1] = userVotingStrategies[0];
        vm.expectRevert(
            abi.encodeWithSelector(DuplicateFound.selector, duplicateStrategies[0].index, duplicateStrategies[1].index)
        );
        _vote(author, proposalId, Choice.For, duplicateStrategies);
    }

    function testCumulativeInvalidStrategy() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, executionStrategy, userVotingStrategies);

        IndexedStrategy[] memory invalidStrategies = new IndexedStrategy[](1);
        invalidStrategies[0] = IndexedStrategy(42, new bytes(0));

        vm.expectRevert();
        _vote(author, proposalId, Choice.For, invalidStrategies);
    }
}
