// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";

/// @title Staked NFT Apechain Voting Strategy
contract StakedNFTApechainVotingStrategy is IVotingStrategy {
    struct TokenStakePosition {
        uint256 poolId;
        uint256 tokenId;
        uint256 stakedAmount;
        bytes ownershipProof;
        bytes balanceProof;
    }

    function getVotingPower(
        uint32 blockNumber,
        address voter,
        bytes calldata params, // (address herodotusContract)
        bytes calldata userParams // (TokenStakePosition[] tokens)
    ) external view override returns (uint256) {
        // Decode params
        address herodotusContract = abi.decode(params, (address));

        // Decode userParams
        TokenStakePosition[] memory tokens = abi.decode(userParams, (TokenStakePosition[]));

        uint256 total = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            _verifyOwnership(tokens[i], blockNumber, voter, herodotusContract);
            _verifyBalance(tokens[i], blockNumber, voter, herodotusContract);
            total += tokens[i].stakedAmount;
        }

        return total;
    }

    // TODO: check that owner checking mechanism is correct (with shadow NFTs)
    function _verifyOwnership(
        TokenStakePosition memory token,
        uint32 blockNumber,
        address voter,
        address herodotusContract
    ) internal view {
        // TODO simulate ownerOf by fetching `_owners[token.tokenId]`
    }

    function _verifyBalance(
        TokenStakePosition memory token,
        uint32 blockNumber,
        address voter,
        address herodotusContract
    ) internal view {
        // TODO: fetch nftPosition[_poolId][token.tokenId]
        // assert nftPosition[_poolId][token.tokenId] == token.stakedAmount
    }
}
