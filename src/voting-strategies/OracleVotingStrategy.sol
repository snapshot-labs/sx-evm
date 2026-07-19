// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @title Oracle Voting Strategy
/// @notice Uses voting power attested offchain by a trusted oracle that signs an EIP-712 `Score` message.
/// @dev The attested voting power must be a pure function of (params, blockNumber, voter): any
///      configuration that affects the score must be encoded in `params`.
contract OracleVotingStrategy is IVotingStrategy, EIP712 {
    /// @notice Thrown when the signature is invalid.
    error InvalidSignature();

    bytes32 private constant SCORE_TYPEHASH =
        keccak256("Score(bytes params,uint256 votingPower,uint32 blockNumber,address voter)");

    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EIP712(name, version) {}

    /// @notice Returns the voting power attested by the oracle.
    /// @param blockNumber The block number signed by the oracle.
    /// @param voter The address to get the voting power of.
    /// @param params Parameter array containing the oracle address and the strategy params.
    /// @param userParams Parameter array containing the attested voting power and the oracle signature.
    function getVotingPower(
        uint32 blockNumber,
        address voter,
        bytes calldata params, // (address signer, bytes params)
        bytes calldata userParams // (uint256 votingPower, bytes signature)
    ) external view override returns (uint256) {
        // Extract the signer and actual strategy params
        (address signer, bytes memory params_) = abi.decode(params, (address, bytes));

        // Extract the voting power and signature (65-byte ECDSA or arbitrary-length EIP-1271, e.g. Safe)
        (uint256 votingPower, bytes memory signature) = abi.decode(userParams, (uint256, bytes));

        // EIP712 signature schema
        bytes32 messageHash = _hashTypedDataV4(
            keccak256(abi.encode(SCORE_TYPEHASH, keccak256(params_), votingPower, blockNumber, voter))
        );

        // Using SignatureChecker, we also support EIP-1271 signatures
        bool valid = SignatureChecker.isValidSignatureNow(signer, messageHash, signature);

        if (!valid) revert InvalidSignature();

        return votingPower;
    }
}
