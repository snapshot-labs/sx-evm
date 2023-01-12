// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

struct Proposal {
    // We store the quroum for each proposal so that if the quorum is changed mid proposal,
    // the proposal will still use the previous quorum *
    uint256 quorum;
    // notice: `uint32::max` corresponds to year ~2106.
    uint32 snapshotTimestamp;
    // * The same logic applies for why we store the 3 timestamps below (which could otherwise
    // be inferred from the votingDelay, minVotingDuration, and maxVotingDuration state variables)
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
