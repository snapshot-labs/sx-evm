// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { ISpaceState } from "src/interfaces/space/ISpaceState.sol";
import { IVotingStrategy } from "src/interfaces/IVotingStrategy.sol";
import { SXUtils } from "../utils/SXUtils.sol";
import { BitPacker } from "../utils/BitPacker.sol";

contract VotingPowerProposalValidationStrategy is IProposalValidationStrategy {
    using SXUtils for IndexedStrategy[];
    using BitPacker for uint256;

    error InvalidStrategyIndex(uint256 index);

    /**
     * @notice  Validates a proposal using the voting strategies to compute the proposal power.
     * @param   author  Author of the proposal
     * @param   userParams  User provided parameters for the voting strategies
     * @param   params  Bytes that should decode to proposalThreshold and allowedStrategies
     * @return  bool  Whether the proposal should be validated or not
     */
    function validate(
        address author,
        bytes calldata params,
        bytes calldata userParams
    ) external override returns (bool) {
        (uint256 proposalThreshold, uint256 allowedStrategies) = abi.decode(params, (uint256, uint256));
        IndexedStrategy[] memory userStrategies = abi.decode(userParams, (IndexedStrategy[]));

        uint256 votingPower = _getCumulativePower(author, uint32(block.timestamp), userStrategies, allowedStrategies);

        return (votingPower >= proposalThreshold);
    }

    function _getCumulativePower(
        address userAddress,
        uint32 timestamp,
        IndexedStrategy[] memory userStrategies,
        uint256 allowedStrategies
    ) internal returns (uint256) {
        // Ensure there are no duplicates to avoid an attack where people double count a strategy
        userStrategies.assertNoDuplicateIndices();

        uint256 totalVotingPower;
        for (uint256 i = 0; i < userStrategies.length; ++i) {
            uint8 strategyIndex = userStrategies[i].index;

            // Check that the strategy is allowed for this proposal
            if (!allowedStrategies.isBitSet(strategyIndex)) {
                revert InvalidStrategyIndex(strategyIndex);
            }

            // The space contract resides at msg.sender
            (address addr, bytes memory params) = ISpaceState(msg.sender).votingStrategiesMap(strategyIndex);

            totalVotingPower += IVotingStrategy(addr).getVotingPower(
                timestamp,
                userAddress,
                params,
                userStrategies[i].params
            );
        }
        return totalVotingPower;
    }
}
