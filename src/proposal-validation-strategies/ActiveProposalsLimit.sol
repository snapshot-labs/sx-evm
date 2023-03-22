// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { ISpace } from "../interfaces/ISpace.sol";
import { GetCumulativePower } from "../utils/GetCumulativePower.sol";

/**
 * @author  Snapshot Labs
 * @title   Active Proposals Limit Proposal
 * @notice  Exposes a function `increaseActiveProposalCount` that will error if
 *          user has reached `MAX_ACTIVE_PROPOSALS` without waiting for `COOLDOWN` to pass.
 *          The counter gets reset everytime `COOLDOWN` has passed.
 */

abstract contract ActiveProposalsLimit {
    // Cooldown to wait before the counter gets reset
    uint32 public constant COOLDOWN = 1 weeks;

    // Maximum number of active proposals per user. Must be != 0
    uint224 public constant MAX_ACTIVE_PROPOSALS = 5;

    mapping(address => uint256) public usersPackedData;

    function increaseActiveProposalCount(address user) internal returns (bool) {
        uint256 packedData = usersPackedData[user];

        // Effectively a uint32 (32 last bits of userInfo)
        uint256 lastTimestamp = uint32(packedData);

        // 256 - 32 == 224 bits
        uint256 activeProposals = packedData >> 32;

        if (lastTimestamp == 0) {
            // First time the user proposes, activeProposals is 1 no matter what
            activeProposals = 1;
        } else if (block.timestamp >= lastTimestamp + COOLDOWN) {
            // Cooldown passed, reset counter
            activeProposals = 1;
        } else if (activeProposals == MAX_ACTIVE_PROPOSALS) {
            // Cooldown has not passed, but user has reached maximum active proposals. Error.
            return false;
        } else {
            // Cooldown has not passed, user has not reached maximum active proposals: increase counter.
            activeProposals += 1;
        }

        // Update storage
        usersPackedData[user] = (activeProposals << 32) + uint32(block.timestamp);
        return true;
    }
}
