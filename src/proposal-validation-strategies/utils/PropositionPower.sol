// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SXUtils } from "../../utils/SXUtils.sol";
import { IndexedStrategy, Strategy } from "../../types.sol";
import { IVotingStrategy } from "../../interfaces/IVotingStrategy.sol";

abstract contract PropositionPower {
    using SXUtils for IndexedStrategy[];

    error InvalidStrategyIndex(uint256 index);

    function _validate(
        address author,
        uint256 proposalThreshold,
        Strategy[] memory allowedStrategies,
        IndexedStrategy[] memory userStrategies
    ) internal returns (bool) {
        uint256 votingPower = _getCumulativePower(author, uint32(block.timestamp), userStrategies, allowedStrategies);
        return (votingPower >= proposalThreshold);
    }

    function _getCumulativePower(
        address userAddress,
        uint32 timestamp,
        IndexedStrategy[] memory userStrategies,
        Strategy[] memory allowedStrategies
    ) internal returns (uint256) {
        // Ensure there are no duplicates to avoid an attack where people double count a strategy
        userStrategies.assertNoDuplicateIndices();

        uint256 totalVotingPower;
        for (uint256 i = 0; i < userStrategies.length; ++i) {
            uint256 strategyIndex = userStrategies[i].index;
            if (strategyIndex >= allowedStrategies.length) revert InvalidStrategyIndex(strategyIndex);
            Strategy memory strategy = allowedStrategies[strategyIndex];

            totalVotingPower += IVotingStrategy(strategy.addr).getVotingPower(
                timestamp,
                userAddress,
                strategy.params,
                userStrategies[i].params
            );
        }
        return totalVotingPower;
    }
}