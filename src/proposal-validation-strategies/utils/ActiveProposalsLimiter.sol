// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title Active Proposals Limiter Proposal Validation Module
/// @notice This module can be used to limit the number of active proposals per author.
abstract contract ActiveProposalsLimiter {
    /// @notice Thrown when the maximum number of active proposals per user is set to 0.
    error MaxActiveProposalsCannotBeZero();

    /// @notice Mapping that stores and encoded Uint256 for each user, as follows:
    //          [0..32] : 32 bits for the timestamp of the latest proposal made by the user
    //          [32..256] : 224 bits for the number of currently active proposals for this user
    mapping(address => uint256) public usersPackedData;

    /// @dev Validates an author by checking if they have reached the maximum number of active proposals at the current timestamp.
    function _validate(address author, uint256 cooldown, uint256 maxActiveProposals) internal returns (bool success) {
        if (maxActiveProposals == 0) revert MaxActiveProposalsCannotBeZero();

        uint256 packedData = usersPackedData[author];

        // Least significant 32 bits is the lastTimestamp
        uint256 lastTimestamp = uint32(packedData);

        // Removing the least significant 32 bits (lastTimestamp) leaves us with the 224 bits for activeProposals
        uint256 activeProposals = packedData >> 32;

        if (lastTimestamp == 0) {
            // First time the user proposes, activeProposals is 1 no matter what
            activeProposals = 1;
        } else if (block.timestamp >= lastTimestamp + cooldown) {
            // Cooldown passed, reset counter
            activeProposals = 1;
        } else if (activeProposals == maxActiveProposals) {
            // Cooldown has not passed, but user has reached maximum active proposals.
            return false;
        } else {
            // Cooldown has not passed, user has not reached maximum active proposals: increase counter
            activeProposals += 1;
        }

        usersPackedData[author] = (activeProposals << 32) + uint32(block.timestamp);
        return true;
    }
}
