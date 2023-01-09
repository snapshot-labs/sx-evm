// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

abstract contract SignatureVerifier is EIP712("boost", "1") {
    error InvalidSignature();
    bytes32 private constant PROPOSE_TYPE_HASH =
        keccak256(
            "Propose(address space,address author,string metadataUri,address executor,"
            "bytes32 executionHash,bytes32 strategiesHash,uint256 salt)"
        );

    function _verifyProposeSig(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 salt,
        address space,
        bytes memory data
    ) internal view {
        (
            address author,
            string memory metadataUri,
            address executionStrategy,
            uint256[] memory usedVotingStrategiesIndices,
            ,
            bytes memory executionParams
        ) = abi.decode(data, (address, string, address, uint256[], bytes[], bytes));

        address _author = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        PROPOSE_TYPE_HASH,
                        space,
                        author,
                        keccak256(bytes(metadataUri)),
                        executionStrategy,
                        keccak256(executionParams),
                        keccak256(abi.encode(usedVotingStrategiesIndices)),
                        salt
                    )
                )
            ),
            v,
            r,
            s
        );

        if (_author != author) revert InvalidSignature();
    }
}
