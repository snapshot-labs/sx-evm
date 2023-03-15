// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { Strategy } from "../types.sol";

contract VanillaProposalValidationStrategy is IProposalValidationStrategy {
    function validate(
        address, // author,
        bytes calldata, // userParams,
        bytes calldata // params
    ) external override returns (bool) {
        return true;
    }
}
