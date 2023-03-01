// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../types.sol";

interface IProxyFactoryEvents {
    event ProxyDeployed(address implementation, address proxy);
}
