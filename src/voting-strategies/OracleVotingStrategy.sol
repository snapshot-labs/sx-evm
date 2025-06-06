// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @title Oracle Voting Strategy
contract OracleVotingStrategy is IVotingStrategy, EIP712 {
    error InvalidSignature();

    bytes32 private constant SCORE_TYPEHASH =
        keccak256("Score(bytes params,uint256 votingPower,uint32 blockNumber,address voter)");

    constructor(string memory name, string memory version) EIP712(name, version) {}

    function getVotingPower(
        uint32 blockNumber,
        address voter,
        bytes calldata params, // (address signer, bytes params)
        bytes calldata userParams // (uint256 votingPower, bytes32 r, bytes32 s, uint8 v)
    ) external view override returns (uint256) {
        // Extract the signer and actual strategy params
        (address signer, bytes memory params_) = abi.decode(params, (address, bytes));

        // Extract information used to verify signature
        (uint256 votingPower, bytes32 r, bytes32 s, uint8 v) = abi.decode(
            userParams,
            (uint256, bytes32, bytes32, uint8)
        );

        // EIP712 signature schema
        bytes32 messageHash = _hashTypedDataV4(
            keccak256(abi.encode(SCORE_TYPEHASH, keccak256(params_), votingPower, blockNumber, voter))
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        // Using SignatureChecker, we also support EIP-1271 signatures
        bool valid = SignatureChecker.isValidSignatureNow(signer, messageHash, signature);

        if (!valid) revert InvalidSignature();

        return votingPower;
    }
}
