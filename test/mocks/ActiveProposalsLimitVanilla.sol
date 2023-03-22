// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../../src/interfaces/IProposalValidationStrategy.sol";
import { ActiveProposalsLimit } from "../../src/proposal-validation-strategies/ActiveProposalsLimit.sol";

// Always returns false
contract ActiveProposalsLimitVanilla is IProposalValidationStrategy, ActiveProposalsLimit {
    function validate(
        address author,
        bytes calldata, // params,
        bytes calldata // userParams
    ) external override returns (bool) {
        return increaseActiveProposalCount(author);
    }
}
