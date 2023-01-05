// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

struct Proposal {
    uint256 quorum;
    // notice: `uint32::max` corresponds to year ~2106.
    uint32 snapshotTimestamp;
    uint32 startTimestamp;
    uint32 minEndTimestamp;
    uint32 maxEndTimestamp;
    address executionStrategy;
    bytes32 executionHash;
}

struct VotingStrategy {
    address addy;
    bytes params;
}
