// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";

// https://github.com/HerodotusDev/herodotus-evm-v2/blob/legacy-contracts/src/modules/EvmFactRegistryModule.sol
interface IEvmFactRegistryModule {
    function accountField(
        uint256 chainId,
        address account,
        uint256 blockNumber,
        AccountField field
    ) external view returns (bytes32);
}

// https://github.com/HerodotusDev/herodotus-evm-v2
// /blob/7e9f98a9e68959a76c27793da92b65b7c9539423/src/interfaces/modules/IEvmFactRegistryModule.sol#L15-L20
enum AccountField {
    NONCE,
    BALANCE,
    STORAGE_ROOT,
    CODE_HASH
}

/// @title Vanilla Voting Strategy
contract VanillaVotingStrategy is IVotingStrategy {
    function getVotingPower(
        uint32 blockNumber,
        address voter,
        bytes calldata params,
        bytes calldata userParams
    ) external pure override returns (uint256) {
        (address herodotus_contract, ) = abi.decode(params, (address));
        IEvmFactRegistryModule herodotus = IEvmFactRegistryModule(herodotus_contract);
        uint256 chainid = block.chainid; // todo: works?

        uint256 balance = herodotus.accountField(chainid, voter, blockNumber, AccountField.BALANCE);

        return balance;
    }
}
