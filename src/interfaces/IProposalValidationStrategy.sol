// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IProposalValidationStrategy is IProposalValidationStrategyErrors {
    function validate() internal;
}
