// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../types.sol";
import "./execution-strategies/IExecutionStrategyErrors.sol";

interface IExecutionStrategy is IExecutionStrategyErrors {
    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory params,
        bytes memory payload
    ) external;

    function getProposalStatus(
        Proposal memory proposal,
        bytes memory params,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain
    ) external view returns (ProposalStatus);
}
