// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { SimpleQuorumExecutionStrategy } from "./../SimpleQuorumExecutionStrategy.sol";
import { Proposal, ProposalStatus, xMetaTransaction } from "../../types.sol";
import { ISocket } from "../../interfaces/socket/ISocket.sol";
import { PlugBase } from "./PlugBase.sol";

/// @title Socket Execution Strategy
contract SocketExecutionStrategy is SimpleQuorumExecutionStrategy, PlugBase {
    uint256 internal maxExecutionGasLimit=10000000;

    constructor(uint256 _quorum, address _socket) PlugBase(_socket) {
        quorum = _quorum;
    }

    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external override {
        // TODO: add relavent checks on the proposal
       
        // send proposal-status and payload to destination Plugs via Socket
        // TODO: fix fees
        xMetaTransaction[] memory transactions = abi.decode(payload, (xMetaTransaction[]));
        for (uint256 i = 0; i < transactions.length; i++) {
            _outbound(
                transactions[i].toChainId,
                maxExecutionGasLimit,
                0,
                abi.encode(ProposalStatus.Executed,bytes(""))
            );
        }
    }

    function _receiveInbound(
        uint256 siblingChainSlug_,
        bytes memory payload_
    ) internal override {}

    function getStrategyType() external pure override returns (string memory) {
        return "SocketExecutionStrategy";
    }
}
