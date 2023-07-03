// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { SimpleQuorumExecutionStrategy } from "./../SimpleQuorumExecutionStrategy.sol";
import { Proposal, ProposalStatus, xMetaTransaction } from "../../types.sol";
import { ISocket } from "../../interfaces/socket/ISocket.sol";
import { PlugBase } from "./PlugBase.sol";

/// @title Socket Execution Strategy
contract SocketReciever is PlugBase {
    constructor(address _socket) PlugBase(_socket) {
    }

    function _receiveInbound(
        uint256 siblingChainSlug_,
        bytes memory payload_
    ) internal override {
        xMetaTransaction[] memory transactions = abi.decode(payload_, (xMetaTransaction[]));
        for (uint256 i = 0; i < transactions.length; i++) {
            bool success;
            (success, ) = transactions[i].to.call(transactions[i].data);
        }
    }

}
