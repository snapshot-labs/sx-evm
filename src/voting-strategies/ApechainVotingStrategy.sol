// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";

struct PackedTrieNode {
    uint256 data1;
    uint256 data2;
    uint256 data3;
}

struct VotingTrieParameters {
    bytes accountProof;
    address account;
    bool committmentHasDelegated;
    uint256 committmentVotingPower;
    PackedTrieNode[] nodes;
}

interface IApeChainVotingPower {
    function computeVotingPower(
        VotingTrieParameters calldata trieParams,
        bytes32 proposalId,
        uint256 blockNumber
    ) external view returns (uint256);
}

/// @title Vanilla Voting Strategy
contract ApechainVotingStrategy is IVotingStrategy {
    function getVotingPower(
        uint32 blockNumber,
        address voter,
        bytes calldata params, // (address herodotusContract)
        bytes calldata userParams // (VotingTrieParameters votingTrieParameters, uint256 proposalId)
    ) external view override returns (uint256) {
        // Decode the parameters
        address contractAddress = abi.decode(params, (address));
        (VotingTrieParameters memory votingTrieParameters, bytes32 proposalId) = abi.decode(
            userParams,
            (VotingTrieParameters, bytes32)
        );
        // Get the contract instance
        IApeChainVotingPower herodotusContract = IApeChainVotingPower(contractAddress);

        // Call the computeVotingPower function
        return herodotusContract.computeVotingPower(votingTrieParameters, proposalId, blockNumber);
    }
}
