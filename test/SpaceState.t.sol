// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./Space.t.sol";

contract SpaceStateTest is SpaceTest {
    function testGetInvalidProposal() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidProposalId.selector, 1));
        // No proposal has been created yet
        space.getProposal(1);
    }
}
