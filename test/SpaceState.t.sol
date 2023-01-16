// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "./Space.t.sol";
import "forge-std/console2.sol";
import "../src/Space.sol";
import "../src/types.sol";
import "../src/voting-strategies/VanillaVotingStrategy.sol";
import "../src/interfaces/space/ISpaceEvents.sol";

contract SpaceStateTest is SpaceTest, SpaceErrors {
    function testGetInvalidProposal() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidProposalId.selector, 1));
        // No proposal has been created yet
        space.getProposal(1);
    }
}
