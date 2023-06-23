// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { SimpleQuorumExecutionStrategy } from "./../SimpleQuorumExecutionStrategy.sol";
import { Proposal, ProposalStatus } from "../../types.sol";
import { ISocket } from "../../interfaces/socket/ISocket.sol";
import { PlugBase } from "./PlugBase.sol";

/// @title Socket Execution Strategy
contract SocketExecutionStrategy is SimpleQuorumExecutionStrategy, PlugBase {
    uint256 internal executionGasLimit=1000000;
    uint256 destChainSlug=0;

    constructor(uint256 _quorum) {
        __SimpleQuorumExecutionStrategy_init(_quorum);
    }

    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external override {
        ProposalStatus proposalStatus = getProposalStatus(proposal, votesFor, votesAgainst, votesAbstain);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }
        // Check that the execution payload matches the payload supplied when the proposal was created
        if (proposal.executionPayloadHash != keccak256(payload)) revert InvalidPayload();

        // send proposal-status and payload to destination Plugs via Socket
        _outbound(
            destChainSlug,
            executionGasLimit,
            10000000,
            abi.encode(proposalStatus,payload)
        );
    }

    function _receiveInbound(
        uint256 siblingChainSlug_,
        bytes memory payload_
    ) internal override {
         (uint8 proposalStatus, bytes memory executionPayload) = abi.decode(
            payload_,
            (uint8, bytes)
        );

        // TODO: if proposal is not finalised, revert

        MetaTransaction memory transaction = abi.decode(executionPayload, (MetaTransaction));
        (success, ) = transaction.to.call{ value: transaction.value }(transaction.data);

        emit ProposalExecuted(keccak256(executionPayload));
    }

    function getStrategyType() external pure override returns (string memory) {
        return "SocketExecutionStrategy";
    }
}
