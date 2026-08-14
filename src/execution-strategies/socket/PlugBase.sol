// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { ISocket } from "../../interfaces/socket/ISocket.sol";
import "forge-std/Test.sol";

abstract contract PlugBase {
    address public plugOwner;
    ISocket socket;

    constructor(address socket_) {
        plugOwner = msg.sender;
        socket = ISocket(socket_);
    }

    //
    // Modifiers
    //
    modifier onlyPlugOwner() {
        require(msg.sender == plugOwner, "no auth");
        _;
    }

    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external onlyPlugOwner {
        socket.connect(siblingChainSlug_, siblingPlug_, inboundSwitchboard_, outboundSwitchboard_);
    }

    // TODO: add get fees functions

    function inbound(uint256 siblingChainSlug_, bytes calldata payload_) external payable {
        require(msg.sender == address(socket), "no auth");
        _receiveInbound(siblingChainSlug_, payload_);
    }

    function _outbound(uint256 chainSlug_, uint256 gasLimit_, uint256 fees_, bytes memory payload_) internal {
        socket.outbound{ value: fees_ }(chainSlug_, gasLimit_, payload_);
    }

    function _receiveInbound(uint256 siblingChainSlug_, bytes memory payload_) internal virtual;

    // function _getChainSlug() internal view returns (uint256) {
    //     return socket.chainSlug();
    // }

    // owner related functions
    function removeOwner() external onlyPlugOwner {
        plugOwner = address(0);
    }
}
