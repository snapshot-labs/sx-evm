// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../../types.sol";

interface IProxyFactoryEvents {
    event ProxyDeployed(address implementation, address proxy);
}
