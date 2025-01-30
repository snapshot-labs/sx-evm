// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IProxyFactory } from "./interfaces/IProxyFactory.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

address constant SPACE_IMPLEM = address(0xC3031A7d3326E47D49BfF9D374d74f364B29CE4D);

/// @title Proxy Factory
/// @notice A contract to deploy and track ERC1967 proxies of a given implementation contract.
contract ProxyFactory is IProxyFactory, Ownable {
    mapping(address implem => uint256 fee) public deploymentFees;

    /// @inheritdoc IProxyFactory
    function deployProxy(
        address implementation,
        bytes memory initializer,
        uint256 saltNonce
    ) external payable override {
        if (implementation == address(0) || implementation.code.length == 0) revert InvalidImplementation();
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, saltNonce));
        if (predictProxyAddress(implementation, salt).code.length > 0) revert SaltAlreadyUsed();
        address proxy = address(new ERC1967Proxy{ salt: salt }(implementation, ""));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = proxy.call(initializer);
        if (!success) revert FailedInitialization();

        uint256 fee = deploymentFees[implementation];
        if (fee > 0) {
            if (msg.value < fee) revert InsufficientFee();
        }

        emit ProxyDeployed(implementation, proxy);
    }

    /// @inheritdoc IProxyFactory
    function predictProxyAddress(address implementation, bytes32 salt) public view override returns (address) {
        return
            address(
                uint160(
                    uint256(
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

    /// @inheritdoc IProxyFactory
    function setDeploymentFee(address implem, uint256 fee) external onlyOwner {
        deploymentFees[implem] = fee;
        emit DeploymentFeeUpdated(implem, fee);
    }

    /// @notice Allows the owner to claim the fees collected by the contract.
    function claimFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
