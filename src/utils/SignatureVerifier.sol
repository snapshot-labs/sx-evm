// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { Choice, IndexedStrategy, Strategy } from "src/types.sol";
import { SXHash } from "src/utils/SXHash.sol";
import { TRUE, FALSE } from "../types.sol";

/// @title EIP712 Signature Verifier
/// @notice Verifies Signatures for Snapshot X actions.
abstract contract SignatureVerifier is EIP712 {
    using SXHash for IndexedStrategy[];
    using SXHash for IndexedStrategy;
    using SXHash for Strategy;

    /// @notice Thrown if a signature is invalid.
    error InvalidSignature();

    /// @notice Thrown if a user has already used a specific salt.
    error SaltAlreadyUsed();

    bytes32 private constant PROPOSE_TYPEHASH =
        keccak256(
            "Propose(address space,address author,string metadataURI,Strategy executionStrategy,"
            "bytes userProposalValidationParams,uint256 salt)"
            "Strategy(address addr,bytes params)"
        );
    bytes32 private constant VOTE_TYPEHASH =
        keccak256(
            "Vote(address space,address voter,uint256 proposalId,uint8 choice,"
            "IndexedStrategy[] userVotingStrategies,string voteMetadataURI)"
            "IndexedStrategy(uint8 index,bytes params)"
        );
    bytes32 private constant UPDATE_PROPOSAL_TYPEHASH =
        keccak256(
            "updateProposal(address space,address author,uint256 proposalId,"
            "Strategy executionStrategy,string metadataURI,uint256 salt)"
            "Strategy(address addr,bytes params)"
        );

    mapping(address author => mapping(uint256 salt => uint256 used)) private usedSalts;

    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EIP712(name, version) {}

    /// @dev Verifies an EIP712 signature for a propose call.
    ///      We use memory instead of calldata here for the `data` argument because of stack constraints.
    function _verifyProposeSig(uint8 v, bytes32 r, bytes32 s, uint256 salt, address space, bytes memory data) internal {
        (
            address author,
            string memory metadataURI,
            Strategy memory executionStrategy,
            bytes memory userProposalValidationParams
        ) = abi.decode(data, (address, string, Strategy, bytes));

        if (usedSalts[author][salt] != FALSE) revert SaltAlreadyUsed();
        // Mark salt as used to prevent replay attacks.
        usedSalts[author][salt] = TRUE;

        bytes32 messageHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    PROPOSE_TYPEHASH,
                    space,
                    author,
                    keccak256(bytes(metadataURI)),
                    executionStrategy.hash(),
                    keccak256(userProposalValidationParams),
                    salt
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        bool valid = SignatureChecker.isValidSignatureNow(author, messageHash, signature);

        if (!valid) revert InvalidSignature();
    }

    /// @dev Verifies an EIP712 signature for a vote call.
    function _verifyVoteSig(uint8 v, bytes32 r, bytes32 s, address space, bytes calldata data) internal view {
        (
            address voter,
            uint256 proposeId,
            Choice choice,
            IndexedStrategy[] memory userVotingStrategies,
            string memory voteMetadataURI
        ) = abi.decode(data, (address, uint256, Choice, IndexedStrategy[], string));

        bytes32 messageHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    VOTE_TYPEHASH,
                    space,
                    voter,
                    proposeId,
                    choice,
                    userVotingStrategies.hash(),
                    keccak256(bytes(voteMetadataURI))
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        bool valid = SignatureChecker.isValidSignatureNow(voter, messageHash, signature);

        if (!valid) revert InvalidSignature();
    }

    /// @dev Verifies an EIP712 signature for an update proposal call.
    ///      We use memory instead of calldata here for the `data` argument because of stack constraints.
    function _verifyUpdateProposalSig(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 salt,
        address space,
        bytes memory data
    ) internal {
        (address author, uint256 proposalId, Strategy memory executionStrategy, string memory metadataURI) = abi.decode(
            data,
            (address, uint256, Strategy, string)
        );

        if (usedSalts[author][salt] != FALSE) revert SaltAlreadyUsed();
        // Mark salt as used to prevent replay attacks.
        usedSalts[author][salt] = TRUE;

        bytes32 messageHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    UPDATE_PROPOSAL_TYPEHASH,
                    space,
                    author,
                    proposalId,
                    executionStrategy.hash(),
                    keccak256(bytes(metadataURI)),
                    salt
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        bool valid = SignatureChecker.isValidSignatureNow(author, messageHash, signature);

        if (!valid) revert InvalidSignature();
    }
}
