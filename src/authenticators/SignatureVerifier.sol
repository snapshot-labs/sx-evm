// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "src/types.sol";

abstract contract SignatureVerifier is EIP712 {
    error InvalidSignature();

    bytes32 private constant STRATEGY_TYPEHASH = keccak256("Strategy(address addy,bytes params)");
    bytes32 private constant INDEXED_STRATEGY_TYPEHASH = keccak256("IndexedStrategy(uint8 index,bytes params)");
    bytes32 private constant PROPOSE_TYPEHASH =
        keccak256(
            "Propose(address space,address author,string metadataUri,Strategy executionStrategy,"
            "IndexedStrategy[] userVotingStrategies,uint256 salt)"
        );

    constructor(string memory name, string memory version) EIP712(name, version) {}

    function _hashString(string memory str) internal pure returns (bytes32) {
        return keccak256(bytes(str));
    }

    function _hashStrategy(Strategy memory strategy) internal pure returns (bytes32) {
        return keccak256(abi.encode(STRATEGY_TYPEHASH, strategy));
    }

    function _hashIndexedStrategies(IndexedStrategy[] memory indexedStrategies) internal pure returns (bytes32) {
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
    ) internal pure returns (bytes32) {
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
            Strategy memory executionStrategy,
            IndexedStrategy[] memory usedVotingStrategies
        ) = abi.decode(data, (address, string, Strategy, IndexedStrategy[]));

        address _author = ECDSA.recover(
            _hashTypedDataV4(_hashPropose(space, author, metadataUri, executionStrategy, usedVotingStrategies, salt)),
            v,
            r,
            s
        );

        if (_author != author) revert InvalidSignature();
    }
}
