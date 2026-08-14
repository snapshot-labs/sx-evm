// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";

/// @title Current Gas Proposal Validation Strategy
/// @notice Strategy to validate a proposal based on the user's current gas balance.
contract CurrentGasProposalValidationStrategy is IProposalValidationStrategy {
    /// @notice Validates an author by checking if they have a balance greater than or equal to the threshold.
    /// @param author Author of the proposal.
    /// @param params ABI encoded array that should contain the following:
    ///                 threshold: Minimum balance required to pass validation.
    /// @return success Whether the proposal was validated.
    function validate(
        address author,
        bytes calldata params, // (uint256 threshold)
        bytes calldata // userParams
    ) external view override returns (bool) {
        // Decode threshold from params
        uint256 threshold = abi.decode(params, (uint256));

        // Ensure author has a balance greater than or equal to threshold
        return author.balance >= threshold;
    }
}
