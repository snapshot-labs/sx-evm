// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { ISpace } from "../interfaces/ISpace.sol";
import { GetCumulativePower } from "../utils/GetCumulativePower.sol";

abstract contract ActiveProposalsLimit {
    uint32 public constant COOLDOWN = 1 weeks;
    uint224 public constant MAX_ACTIVE_PROPOSALS = 5;

    mapping(address => uint256) public users;

    function increaseActiveProposalCount(address user) internal returns (bool) {
        uint256 userInfo = users[user];

        // Effectively a uint32 (32 last bits of userInfo)
        uint256 lastTimestamp = uint32(userInfo);

        // 256 - 32 == 224 bits
        uint256 activeProposals = userInfo >> 32;

        if (lastTimestamp == 0) {
            // First time the user votes
            activeProposals = 1;
        } else if (block.timestamp >= lastTimestamp + COOLDOWN) {
            // Cooldown passed, reset
            activeProposals = 1;
        } else if (activeProposals == MAX_ACTIVE_PROPOSALS) {
            return false;
        } else {
            // Increase
            activeProposals += 1;
        }

        // Update storage
        users[user] = (activeProposals << 32) + uint32(block.timestamp);
        return true;
    }
}
