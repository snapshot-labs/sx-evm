// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { ISpaceState } from "src/interfaces/space/ISpaceState.sol";
import { IVotingStrategy } from "src/interfaces/IVotingStrategy.sol";
import { SXUtils } from "../utils/SXUtils.sol";
import { BitPacker } from "../utils/BitPacker.sol";
import { ActiveProposalsLimiter } from "./ActiveProposalsLimiter.sol";
import { VotingPowerProposalValidationStrategy } from "./VotingPowerProposalValidationStrategy.sol";

contract VotingPowerAndActiveProposalsLimiterValidationStrategy is
    IProposalValidationStrategy,
    ActiveProposalsLimiter,
    VotingPowerProposalValidationStrategy
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
    function validate(
        address author,
        bytes memory params,
        bytes memory userParams
    )
        public
        override(IProposalValidationStrategy, ActiveProposalsLimiter, VotingPowerProposalValidationStrategy)
        returns (bool)
    {
        ActiveProposalsLimiter.validate(author, new bytes(0), new bytes(0));
        VotingPowerProposalValidationStrategy.validate(author, params, userParams);

        return true;
    }
}
