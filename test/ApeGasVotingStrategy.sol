// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { ApeGasVotingStrategy } from "../src/voting-strategies/ApeGasVotingStrategy.sol";
import { VotingTrieParameters, PackedTrieNode } from "../src/voting-strategies/ApeGasVotingStrategy.sol";

contract ApeGasVotingStrategyTest is Test {
    ApeGasVotingStrategy public apeGasVotingStrategy;

    address public voter = makeAddr("user"); // TODO change
    uint32 blockNumber = 100; // TODO change
    address public herodotusContract = makeAddr("herodotusContract"); // TODO change
    bytes params = abi.encode(herodotusContract);

    bytes accountProof = bytes("accountProof");
    PackedTrieNode[] nodes = new PackedTrieNode[](0); // TODO change
    VotingTrieParameters votingTrieParameters =
        VotingTrieParameters({
            accountProof: accountProof,
            account: voter,
            committmentHasDelegated: false,
            committmentVotingPower: 1,
            nodes: nodes
        });
    bytes userParams = abi.encode(votingTrieParameters);

    function setUp() public {
        apeGasVotingStrategy = new ApeGasVotingStrategy();
    }

    function testGetVotingPower() public view {
        uint256 votingPower = apeGasVotingStrategy.getVotingPower(blockNumber, voter, params, userParams);

        assertEq(votingPower, 1); // TODO update vp
    }

    function testInvalidBlockNumber() public view {
        uint32 invalidBlockNumber = blockNumber - 1;
        uint256 votingPower = apeGasVotingStrategy.getVotingPower(invalidBlockNumber, voter, params, userParams);

        assertEq(votingPower, 0);
    }

    function testInvalidVoter() public {
        address invalidVoter = address(1337);
        vm.expectRevert(abi.encodeWithSelector(ApeGasVotingStrategy.InvalidVoter.selector));
        uint256 votingPower = apeGasVotingStrategy.getVotingPower(blockNumber, invalidVoter, params, userParams);

        assertEq(votingPower, 0);
    }
}
