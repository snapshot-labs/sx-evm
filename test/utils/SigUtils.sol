// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

abstract contract SigUtils {
    string private constant name = "SnapshotX";
    string private constant version = "1";

    function _generateProposeDigest(
        address authenticator,
        address space,
        address author,
        string memory metadataUri,
        address executionStrategy,
        uint256[] memory usedVotingStrategiesIndices,
        bytes memory executionParams,
        uint256 salt
    ) internal view returns (bytes32) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                keccak256(
                    abi.encode(
                        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                        keccak256(bytes(name)),
                        keccak256(bytes(version)),
                        block.chainid,
                        address(authenticator)
                    )
                ),
                keccak256(
                    abi.encode(
                        keccak256(
                            "Propose(address space,address author,string metadataUri,address executor,bytes32 executionHash,bytes32 strategiesHash,uint256 salt)"
                        ),
                        space,
                        author,
                        keccak256(bytes(metadataUri)),
                        executionStrategy,
                        keccak256(executionParams),
                        keccak256(abi.encode(usedVotingStrategiesIndices)),
                        salt
                    )
                )
            )
        );

        return digest;
    }
}
