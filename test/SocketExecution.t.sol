// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import { SpaceTest } from "./utils/Space.t.sol";
import "../src/execution-strategies/socket/SocketExecutionStrategy.sol";
import "../src/execution-strategies/socket/SocketReciever.sol";
import "./mocks/Socket.sol";
import { Proposal, ProposalStatus, FinalizationStatus, xMetaTransaction, Enum } from "../src/types.sol";
import { IExecutionStrategy } from "../src/interfaces/IExecutionStrategy.sol";
import { Choice, IndexedStrategy, ProposalStatus, Strategy } from "../src/types.sol";

contract SocketExecution is SpaceTest {
    SocketExecutionStrategy public sender;
    SocketReciever public reciever;
    Socket public mockSocket__;

    uint256 senderChainSlug = 1;
    uint256 receiverChainSlug = 2;
    address public constant fastSwitchboard = address(1);
    address public constant optimisticSwitchboard = address(2);

    address public recipient = address(0xc0ffee);

    function testExecProposal() public {
        mockSocket__ = new Socket(senderChainSlug, receiverChainSlug);
        sender = new SocketExecutionStrategy(quorum, address(mockSocket__));
        reciever = new SocketReciever(address(mockSocket__));

        // wiring -- let both sender and receiver know about each other
        // this makes sure only the configured addresses can execute and call each other
        reciever.connect(senderChainSlug, address(sender), fastSwitchboard, fastSwitchboard);
        sender.connect(receiverChainSlug, address(reciever), fastSwitchboard, fastSwitchboard);

        // we create an xChain Meta-Tx
        xMetaTransaction[] memory transactions = new xMetaTransaction[](1);

        // we create a meta-tx that is to be sent to receiverChainSlug
        transactions[0] = xMetaTransaction(recipient, receiverChainSlug, 1, "", Enum.Operation.Call, 0);

        // create new proposal
        uint256 proposalId = _createProposal(
            author,
            proposalMetadataURI,
            Strategy(address(sender), abi.encode(transactions)),
            new bytes(0)
        );
        vm.warp(block.timestamp + space.minVotingDuration());

        // since the quorum is 1, we should be able to execute after this
        _vote(author, proposalId, Choice.For, userVotingStrategies, voteMetadataURI); // 1

        // execute
        space.execute(proposalId, abi.encode(transactions));
    }
}
