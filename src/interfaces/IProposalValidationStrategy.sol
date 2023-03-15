// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {
    IProposalValidationStrategyErrors
} from "./proposal-validation-strategies/IProposalValidationStrategyErrors.sol";
import { Strategy } from "../types.sol";

interface IProposalValidationStrategy is IProposalValidationStrategyErrors {
    function validate(address author, bytes calldata userParams, bytes calldata params) external returns (bool);
}
