// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { ActiveProposalsLimiter } from "./utils/ActiveProposalsLimiter.sol";

/**
 * @author  Snapshot Labs
 * @title   Active Proposals Limiter
 * @notice  Exposes a function `increaseActiveProposalCount` that will error if
 *          user has reached `maxActiveProposals` without waiting for `cooldown` to pass.
 *          The counter gets reset everytime `cooldown` has passed.
 */
contract ActiveProposalsLimiterProposalValidationStrategy is ActiveProposalsLimiter, IProposalValidationStrategy {
    constructor(uint32 _cooldown, uint224 _maxActiveProposals) ActiveProposalsLimiter(_cooldown, _maxActiveProposals) {}

    function validate(
        address author,
        bytes calldata /* params */,
        bytes calldata /* userParams*/
    ) external override returns (bool) {
        return _validate(author);
    }
}
