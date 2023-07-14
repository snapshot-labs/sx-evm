// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ERC1967Proxy } from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IProxyFactory } from "./interfaces/IProxyFactory.sol";

interface ContractDeployer {
    function getNewAddressCreate2(
        address _sender,
        bytes32 _bytecodeHash,
        bytes32 _salt,
        bytes calldata _input
    ) external view returns (address);
}

/// @title ZKSync Proxy Factory
/// @notice A contract to deploy and track ERC1967 proxies of a given implementation contract.
contract ProxyFactory is IProxyFactory {
    address private constant CONTRACT_DEPLOYER = address(0x0000000000000000000000000000000000008006);

    /// @inheritdoc IProxyFactory
    function deployProxy(address implementation, bytes memory initializer, uint256 saltNonce) external override {
        if (implementation == address(0) || implementation.code.length == 0) revert InvalidImplementation();
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, keccak256(initializer), saltNonce));
        if (predictProxyAddress(implementation, salt).code.length > 0) revert SaltAlreadyUsed();
        address proxy = address(new ERC1967Proxy{ salt: salt }(implementation, ""));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = proxy.call(initializer);
        if (!success) revert FailedInitialization();

        emit ProxyDeployed(implementation, proxy);
    }

    /// @inheritdoc IProxyFactory
    function predictProxyAddress(address implementation, bytes32 salt) public view override returns (address) {
        return
            ContractDeployer(CONTRACT_DEPLOYER).getNewAddressCreate2(
                address(this),
                keccak256(type(ERC1967Proxy).creationCode),
                salt,
                abi.encodePacked(implementation)
            );
    }
}
