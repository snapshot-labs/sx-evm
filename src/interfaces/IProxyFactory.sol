// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./factory/IProxyFactoryErrors.sol";
import "./factory/IProxyFactoryEvents.sol";

import "../types.sol";

interface IProxyFactory is IProxyFactoryErrors, IProxyFactoryEvents {
    function deployProxy(address implementation, bytes memory initializer, bytes32 salt) external;

    function predictProxyAddress(address implementation, bytes32 salt) external view returns (address);
}
