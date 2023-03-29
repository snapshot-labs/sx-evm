// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { Strategy, IndexedStrategy } from "../src/types.sol";
import { CompVotingStrategy } from "../src/voting-strategies/CompVotingStrategy.sol";
import { VanillaVotingStrategy } from "../src/voting-strategies/VanillaVotingStrategy.sol";
import {
    VotingPowerProposalValidationStrategy
} from "../src/proposal-validation-strategies/VotingPowerProposalValidationStrategy.sol";
import { CompToken } from "./mocks/CompToken.sol";

contract VotingPowerProposalValidationTest is SpaceTest {
    error DuplicateFound(uint8 index);
    uint256 internal proposalThreshold = 100;
    CompToken internal compToken;
    IndexedStrategy[] internal userPropositionPowerStrategies;

    function setUp() public virtual override {
        super.setUp();

        compToken = new CompToken();
        compToken.mint(author, 100);
        vm.prank(author);
        compToken.delegate(author);
        vm.roll(block.number + 1);

        // We use a comp token strategy so that we can vary voting power easily and test the proposal threshold
        Strategy memory compVotingStrategy = Strategy(
            address(new CompVotingStrategy()),
            abi.encodePacked(address(compToken))
        );
        Strategy[] memory powerStrategies = new Strategy[](1);
        powerStrategies[0] = compVotingStrategy;
        string[] memory metadataURIs = new string[](1);
        space.addVotingStrategies(powerStrategies, metadataURIs);

        // The comp token strategy will reside at index 1, so we need to use and allowed strategy bit array of ...00010 = 2
        Strategy memory votingPowerProposalValidationStrategy = Strategy(
            address(new VotingPowerProposalValidationStrategy()),
            abi.encode(proposalThreshold, 2)
        );
        space.setProposalValidationStrategy(votingPowerProposalValidationStrategy);

        // The Comp token strategy is at index 1 of the proposal validation strategies
        userPropositionPowerStrategies.push(IndexedStrategy(1, new bytes(0)));
    }

    function testPropose() public {
        _createProposal(author, proposalMetadataURI, executionStrategy, abi.encode(userPropositionPowerStrategies));
    }

    function testProposeInsufficientVotingPower() public {
        vm.prank(author);
        compToken.burn(author, 1); // Voting power of the author is now 99 when the proposal threshold is 100
        vm.roll(block.number + 1);
        vm.expectRevert(FailedToPassProposalValidation.selector);
        _createProposal(author, proposalMetadataURI, executionStrategy, abi.encode(userPropositionPowerStrategies));
    }

    function testProposeInvalidUserVotingStrategy() public {
        IndexedStrategy[] memory invalidUserPropositionPowerStrategies = new IndexedStrategy[](1);
        invalidUserPropositionPowerStrategies[0] = IndexedStrategy(42, new bytes(0));

        // out of bounds revert
        vm.expectRevert();
        _createProposal(
            author,
            proposalMetadataURI,
            executionStrategy,
            abi.encode(invalidUserPropositionPowerStrategies)
        );
    }

    function testProposeDuplicateUserVotingStrategy() public {
        IndexedStrategy[] memory invalidUserPropositionPowerStrategies = new IndexedStrategy[](4);
        invalidUserPropositionPowerStrategies[0] = IndexedStrategy(0, new bytes(0));
        invalidUserPropositionPowerStrategies[1] = IndexedStrategy(1, new bytes(0));
        invalidUserPropositionPowerStrategies[2] = IndexedStrategy(2, new bytes(0));
        invalidUserPropositionPowerStrategies[3] = IndexedStrategy(0, new bytes(0)); // Duplicate index

        vm.expectRevert(abi.encodeWithSelector(DuplicateFound.selector, 0));
        _createProposal(
            author,
            proposalMetadataURI,
            executionStrategy,
            abi.encode(invalidUserPropositionPowerStrategies)
        );
    }

    function testProposeMultipleVotingStrategies() public {
        // Using 2 vanilla strategies for proposition power
        VanillaVotingStrategy additionalStrategy = new VanillaVotingStrategy();
        Strategy[] memory propositionPowerStrategies = new Strategy[](2);
        propositionPowerStrategies[0] = Strategy(address(additionalStrategy), new bytes(0));
        propositionPowerStrategies[1] = Strategy(address(additionalStrategy), new bytes(0));
        string[] memory propositionPowerMetadataURIs = new string[](2);
        space.addVotingStrategies(propositionPowerStrategies, propositionPowerMetadataURIs);

        // Using a proposal threshold of 2, ...001100 = 12
        Strategy memory votingPowerProposalValidationStrategy = Strategy(
            address(new VotingPowerProposalValidationStrategy()),
            abi.encode(2, 12)
        );
        space.setProposalValidationStrategy(votingPowerProposalValidationStrategy);

        IndexedStrategy[] memory newUserPropositionPowerStrategies = new IndexedStrategy[](2);
        newUserPropositionPowerStrategies[0] = IndexedStrategy(2, new bytes(0));
        newUserPropositionPowerStrategies[1] = IndexedStrategy(3, new bytes(0));

        _createProposal(author, proposalMetadataURI, executionStrategy, abi.encode(newUserPropositionPowerStrategies));
    }
}
