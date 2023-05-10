// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Authenticator } from "./Authenticator.sol";

/// @title Vanilla Authenticator
contract VanillaAuthenticator is Authenticator {
    function authenticate(address target, bytes4 functionSelector, bytes memory data) external {
        // No authentication is performed.
        _call(target, functionSelector, data);
    }
}
