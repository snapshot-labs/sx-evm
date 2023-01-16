// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IVotingStrategy {
    function getVotingPower(
        uint256 timestamp,
        address voterAddress,
        bytes calldata params,
        bytes calldata userParams
    ) external returns (uint256 votingPower);
}
