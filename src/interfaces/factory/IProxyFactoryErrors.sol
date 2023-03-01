// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IProxyFactoryErrors {
    error SaltAlreadyUsed();
    error FailedInitialization();
    error InvalidImplementation();
}
