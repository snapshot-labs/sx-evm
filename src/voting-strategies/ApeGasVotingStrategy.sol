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
        uint256 blockNumber
    ) external view returns (uint256);
}

/// @title Ape Gas Voting Strategy
/// @notice Uses the Ape gas balance of a user to determine their voting power.
/// @notice Powered by Herodotus.
contract ApeGasVotingStrategy is IVotingStrategy {
    error InvalidVoter();

    function getVotingPower(
        uint32 blockNumber,
        address voter,
        bytes calldata params, // (address herodotusContract, bytes32 delegateId, address delegateRegistry)
        bytes calldata userParams // (VotingTrieParameters votingTrieParameters)
    ) external view override returns (uint256) {
        // Decode the parameters
        (address herodousContractAddress, bytes32 delegateId, address delegateRegistry) = abi.decode(
            params,
            (address, bytes32, address)
        );
        VotingTrieParameters memory votingTrieParameters = abi.decode(userParams, (VotingTrieParameters));
        // Get the contract instance
        IApeChainVotingPower herodotusContract = IApeChainVotingPower(contractAddress);

        // Check if the voter is the same as the account in the votingTrieParameters
        if (voter != votingTrieParameters.account) {
            revert InvalidVoter();
        }

        // Call the computeVotingPower function
        return herodotusContract.computeVotingPower(votingTrieParameters, blockNumber, delegateId, delegateRegistry);
    }
}
