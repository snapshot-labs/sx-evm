// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { Strategy, UpdateSettingsCalldata } from "../src/types.sol";
import {
    CurrentGasProposalValidationStrategy
} from "../src/proposal-validation-strategies/CurrentGasProposalValidationStrategy.sol";

contract CurrentGasTest is SpaceTest {
    CurrentGasProposalValidationStrategy internal currentGasProposalValidationStrategy;
    uint256 public constant THRESHOLD = 1 ether; // minimum of 1 ETH

    function setUp() public override {
        super.setUp();

        currentGasProposalValidationStrategy = new CurrentGasProposalValidationStrategy();

        Strategy memory newProposalStrategy = Strategy(
            address(currentGasProposalValidationStrategy),
            abi.encode(THRESHOLD)
        );
        space.updateSettings(
            UpdateSettingsCalldata(
                NO_UPDATE_UINT32,
                NO_UPDATE_UINT32,
                NO_UPDATE_UINT32,
                NO_UPDATE_STRING,
                NO_UPDATE_STRING,
                newProposalStrategy,
                "",
                NO_UPDATE_ADDRESSES,
                NO_UPDATE_ADDRESSES,
                NO_UPDATE_STRATEGIES,
                NO_UPDATE_STRINGS,
                NO_UPDATE_UINT8S
            )
        );
    }

    function testHasJustEnoughGas() public {
        vm.deal(author, THRESHOLD);
        _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
    }

    function testHasEnoughGas() public {
        vm.deal(author, THRESHOLD + 1);
        _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
    }

    function testHasNotEnoughGas() public {
        vm.deal(author, THRESHOLD - 1);
        vm.expectRevert(abi.encodeWithSelector(FailedToPassProposalValidation.selector));
        _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
    }
}
