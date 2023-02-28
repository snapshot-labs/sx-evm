// SPDX-License-Identifier: UNLICENSED

import "../../src/Space.sol";

pragma solidity ^0.8.15;

// Inheriting from the Space contract V1 ensures that there are no storage collisions.
contract SpaceV2 is Space {
    uint256 magicNumber;

    function setMagicNumber(uint256 newMagicNumber) public onlyOwner {
        magicNumber = newMagicNumber;
    }

    function getMagicNumber() public view returns (uint256) {
        return magicNumber;
    }
}
