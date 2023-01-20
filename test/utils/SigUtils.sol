// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../src/types.sol";
import { SOCHash } from "../../src/utils/SOCHash.sol";

abstract contract SigUtils {
    using SOCHash for Strategy;
    using SOCHash for IndexedStrategy[];

    string private name;
    string private version;
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 private constant PROPOSE_TYPEHASH =
        keccak256(
            "Propose(address space,address author,string metadataUri,Strategy executionStrategy,"
            "IndexedStrategy[] userVotingStrategies,uint256 salt)"
        );

    constructor(string memory _name, string memory _version) {
        name = _name;
        version = _version;
    }

    function _getProposeDigest(
        address authenticator,
        address space,
        address author,
        string memory metadataUri,
        Strategy memory executionStrategy,
        IndexedStrategy[] memory usedVotingStrategies,
        uint256 salt
    ) internal view returns (bytes32) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                keccak256(
                    abi.encode(
                        DOMAIN_TYPEHASH,
                        keccak256(bytes(name)),
                        keccak256(bytes(version)),
                        block.chainid,
                        authenticator
                    )
                ),
                keccak256(
                    abi.encode(
                        PROPOSE_TYPEHASH,
                        space,
                        author,
                        keccak256(bytes(metadataUri)),
                        executionStrategy.hash(),
                        usedVotingStrategies.hash(),
                        salt
                    )
                )
            )
        );

        return digest;
    }
}
