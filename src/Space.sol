// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Ownable? Eip712?
contract Space {
    uint256 private votingDelay;
    uint256 private minVotingDuration;
    uint256 private maxVotingDuration;

    uint256 private proposalThreshold;
    uint256 private quorum;
    mapping (address => bool) private executionStrategies;
    address[] private votingStrategies;
}
