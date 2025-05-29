// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";

/// @title Current Gas Proposal Validation Strategy
contract CurrentGasProposalValidationStrategy is IProposalValidationStrategy {
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
