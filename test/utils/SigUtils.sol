// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../src/types.sol";

abstract contract SigUtils {
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public constant STRATEGY_TYPEHASH = keccak256("Strategy(address addy,bytes params)");
    bytes32 public constant INDEXED_STRATEGY_TYPEHASH = keccak256("IndexedStrategy(uint8 index,bytes params)");
    bytes32 public constant PROPOSE_TYPEHASH =
        keccak256(
            "Propose(address space,address author,string metadataUri,Strategy executionStrategy,IndexedStrategy[] userVotingStrategies,uint256 salt)"
        );

    string private constant name = "SnapshotX";
    string private constant version = "1";

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
                        _hashString(name),
                        _hashString(version),
                        block.chainid,
                        authenticator
                    )
                ),
                _hashPropose(space, author, metadataUri, executionStrategy, usedVotingStrategies, salt)
            )
        );

        return digest;
    }

    function _hashString(string memory str) internal pure returns (bytes32) {
        return keccak256(bytes(str));
    }

    function _hashStrategy(Strategy memory strategy) internal view returns (bytes32) {
        return keccak256(abi.encode(STRATEGY_TYPEHASH, strategy));
    }

    function _hashIndexedStrategies(IndexedStrategy[] memory indexedStrategies) internal view returns (bytes32) {
        bytes32[] memory indexedStrategyHashes = new bytes32[](indexedStrategies.length);
        for (uint256 i = 0; i < indexedStrategies.length; i++) {
            indexedStrategyHashes[i] = keccak256(abi.encode(INDEXED_STRATEGY_TYPEHASH, indexedStrategies[i]));
        }
        return keccak256(abi.encodePacked(indexedStrategyHashes));
    }

    function _hashPropose(
        address space,
        address author,
        string memory metadataUri,
        Strategy memory executionStrategy,
        IndexedStrategy[] memory usedVotingStrategies,
        uint256 salt
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PROPOSE_TYPEHASH,
                    space,
                    author,
                    _hashString(metadataUri),
                    _hashStrategy(executionStrategy),
                    _hashIndexedStrategies(usedVotingStrategies),
                    salt
                )
            );
    }
}
