// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

abstract contract TimestampResolver {
    error TimestampInFuture();
    mapping(uint256 => uint256) public timestampToBlockNumber;

    function resolveSnapshotTimestamp(uint256 timestamp) external returns (uint256) {
        if (timestamp > block.timestamp) revert TimestampInFuture();

        uint256 blockNumber = timestampToBlockNumber[timestamp];
        if (blockNumber != 0) {
            // Timestamp already resolved, return the previously resolved block number
            return blockNumber;
        }
        // Timestamp not yet resolved, resolve it to the current block number and return it
        timestampToBlockNumber[timestamp] = block.number;
        return block.number;
    }
}
