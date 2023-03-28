// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { Strategy } from "../src/types.sol";
import {
    VotingPowerProposalValidationStrategy
} from "../src/proposal-validation-strategies/VotingPowerProposalValidationStrategy.sol";

contract VotingPowerProposalValidationTest is SpaceTest {
    function setUp() public virtual override {
        super.setUp();

        Strategy memory votingPowerProposalValidationStrategy = Strategy(
            address(new VotingPowerProposalValidationStrategy()),
            abi.encode(proposalThreshold, votingStrategies)
        );
        space.setProposalValidationStrategy(votingPowerProposalValidationStrategy);
    }

    // function testPropose() public {

    // }
}
