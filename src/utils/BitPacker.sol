// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// @dev Append only bit packing library
library BitPacker {
    function setBit(uint256 value, uint8 index, bool bit) internal pure returns (uint256) {
        uint256 mask = uint256(1 << index);
        if (bit) {
            return value | mask;
        } else {
            return value & ~mask;
        }
    }

    function isBitSet(uint256 value, uint8 index) internal pure returns (bool) {
        uint256 mask = uint256(1 << index);
        return (value & mask) != 0;
    }
}
