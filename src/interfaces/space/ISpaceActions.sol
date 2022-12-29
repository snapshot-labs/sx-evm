// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ISpaceActions {
    function propose(
        address proposerAddress,
        string calldata metadataUri,
        address executionStrategy,
        uint256[] calldata usedVotingStrategiesIndices,
        bytes[] calldata userVotingStrategyParams,
        bytes calldata executionParams
    ) external;

    function vote() external;

    function finalize() external;
}
