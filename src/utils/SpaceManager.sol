// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SpaceManager is OwnableUpgradeable {
    mapping(address => bool) internal spaces;

    function __SpaceManager_init(address[] memory _spaces) internal initializer {
        for (uint256 i = 0; i < _spaces.length; i++) {
            spaces[_spaces[i]] = true;
        }
    }

    function enableSpace(address space) public onlyOwner {
        spaces[space] = true;
    }

    function disableSpace(address space) public onlyOwner {
        spaces[space] = false;
    }

    function isSpaceEnabled(address space) external view returns (bool) {
        return spaces[space];
    }

    /// @dev Returns true if `account` is a contract.
    /// @param account The address being queried
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
