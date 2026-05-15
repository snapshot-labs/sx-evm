// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Proposal, ProposalStatus } from "../types.sol";
import { IExecutionStrategyErrors } from "./execution-strategies/IExecutionStrategyErrors.sol";

/// @title Execution Strategy Interface
interface IExecutionStrategy is IExecutionStrategyErrors {
    function execute(
        uint256 proposalId,
        Proposal memory proposal,
        bool quorumReached,
        bool supportAchieved,
        bytes memory payload
    ) external;

    function getProposalStatus(
        Proposal memory proposal,
        bool quorumReached,
        bool supportAchieved
    ) external view returns (ProposalStatus);

    /// @notice Returns the quorum value for this strategy.
    /// @dev Needed so Space.vote() can read the quorum for encrypted comparison.
    function getQuorum() external view returns (uint256);

    function getStrategyType() external view returns (string memory);
}
