// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

abstract contract SignatureVerifier is EIP712("boost", "1") {
    bytes32 private constant PROPOSE_TYPE_HASH =
        keccak256(
            "Propose(address authenticator,address space,address author,string metadataUri,address executor,bytes32 executionHash,bytes32 strategiesHash,uint256 salt)"
        );

    function _verifyProposeSig(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 salt,
        address space,
        bytes memory data
    ) internal {
        
    }
}
