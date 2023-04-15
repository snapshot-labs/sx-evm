// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { ActiveProposalsLimiter } from "./utils/ActiveProposalsLimiter.sol";
import { PropositionPower } from "./utils/PropositionPower.sol";

contract VotingPowerAndActiveProposalsLimiterValidationStrategy is
    ActiveProposalsLimiter,
    PropositionPower,
    IProposalValidationStrategy
{
    // solhint-disable-next-line no-empty-blocks
    constructor(uint32 _cooldown, uint224 _maxActiveProposals) ActiveProposalsLimiter(_cooldown, _maxActiveProposals) {}

    /**
     * @notice  Validates a proposal using the voting strategies to compute the proposal power, while also ensuring
                that the author respects the active proposals limit.
     * @param   author  Author of the proposal
     * @param   userParams  User provided parameters for the voting strategies
     * @param   params  Bytes that should decode to proposalThreshold and allowedStrategies
     * @return  bool  Whether the proposal should be validated or not
     */
    function validate(address author, bytes calldata params, bytes calldata userParams) public returns (bool) {
        (uint256 proposalThreshold, Strategy[] memory allowedStrategies) = abi.decode(params, (uint256, Strategy[]));
        IndexedStrategy[] memory userStrategies = abi.decode(userParams, (IndexedStrategy[]));

        return _validate(author) && _validate(author, proposalThreshold, allowedStrategies, userStrategies);
    }
}
