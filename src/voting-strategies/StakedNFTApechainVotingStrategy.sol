// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";

/// @title Staked NFT Apechain Voting Strategy
contract StakedNFTApechainVotingStrategy is IVotingStrategy {
    uint256 constant BAYC_POOL_ID = 1; // Taken from the ApeCoinStaking contract
    uint256 constant MAYC_POOL_ID = 2; // Taken from the ApeCoinStaking contract
    uint256 constant BAKC_POOL_ID = 3; // Taken from the ApeCoinStaking contract

    struct TokenStakePosition {
        uint256 tokenId;
        uint256 stakedAmount;
    }

    function getVotingPower(
        uint32 blockNumber,
        address voter,
        bytes calldata params, // (address herodotusContract)
        bytes calldata userParams // (TokenStakePosition[] baycs, TokenStakePosition[] maycs, TokenStakePosition[] bakcs)
    ) external view override returns (uint256) {
        // Decode params
        address herodotusContract = abi.decode(params, (address));

        // Decode userParams
        (
            TokenStakePosition[] memory baycTokens,
            TokenStakePosition[] memory maycTokens,
            TokenStakePosition[] memory bakcTokens
        ) = abi.decode(userParams, (TokenStakePosition[], TokenStakePosition[], TokenStakePosition[]));

        // Check that the owner is indeed the owner of each token
        _checkOwner(BAYC_POOL_ID, baycTokens, voter, blockNumber, herodotusContract);
        _checkOwner(MAYC_POOL_ID, maycTokens, voter, blockNumber, herodotusContract);
        _checkOwner(BAKC_POOL_ID, bakcTokens, voter, blockNumber, herodotusContract);

        uint256 total = 0;
        total += _stakedTotal(BAYC_POOL_ID, baycTokens, blockNumber, herodotusContract);
        total += _stakedTotal(MAYC_POOL_ID, maycTokens, blockNumber, herodotusContract);
        total += _stakedTotal(BAKC_POOL_ID, bakcTokens, blockNumber, herodotusContract);

        return total;
    }

    function _stakedTotal(
        uint256 poolId,
        TokenStakePosition[] memory tokens,
        uint32 blockNumber,
        address herodotusContract
    ) internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            // TODO: fetch nftPosition[_poolId][tokenIds[i]]
            // total += nftPosition[_poolId][tokens[i].tokenId];
            // assert nftPosition[_poolId][tokens[i].tokenId] == tokens[i].stakedAmount
            total += tokens[i].stakedAmount;
        }
        return 0;
    }

    // TODO: check that owner checking mechanism is correct (with shadow NFTs)
    function _checkOwner(
        uint256 poolId,
        TokenStakePosition[] memory tokens,
        address owner,
        uint32 blockNumber,
        address herodotusContract
    ) internal view {
        for (uint256 i = 0; i < tokens.length; i++) {
            // TODO simulate ownerOf by fetching `_owners[tokenId]`
        }
    }
}
