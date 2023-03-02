// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Space.sol";
import "./interfaces/IProxyFactory.sol";
import "./types.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title   Proxy Factory
 * @notice  A contract to deploy and track ERC1967 proxies of a given UUPSUpgradeable implementation contract.
 * @author  Snapshot Labs
 */
contract ProxyFactory is IProxyFactory {
    function deployProxy(address implementation, bytes memory initializer, bytes32 salt) external override {
        if (implementation == address(0) || implementation.code.length == 0) revert InvalidImplementation();
        if (predictProxyAddress(implementation, salt).code.length > 0) revert SaltAlreadyUsed();
        address proxy = address(new ERC1967Proxy{ salt: salt }(implementation, ""));
        (bool success, ) = proxy.call(initializer);
        if (!success) revert FailedInitialization();

        emit ProxyDeployed(implementation, proxy);
    }

    function predictProxyAddress(address implementation, bytes32 salt) public view override returns (address) {
        return
            address(
                uint160(
                    uint(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(implementation, ""))
                                )
                            )
                        )
                    )
                )
            );
    }
}
