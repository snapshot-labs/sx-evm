// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Space.sol";
import "./interfaces/ISpaceFactory.sol";
import "./types.sol";

/**
 * @author  SnapshotLabs
 * @title   Space Factory Contract.
 */
contract SpaceFactory is ISpaceFactory {
    function createSpace(
        address owner,
        uint32 votingDelay,
        uint32 minVotingDuration,
        uint32 maxVotingDuration,
        uint256 proposalThreshold,
        uint256 quorum,
        Strategy[] calldata votingStrategies,
        address[] calldata authenticators,
        address[] calldata executionStrategiesAddresses,
        bytes32 salt
    ) external {
        address space = address(
            new Space{ salt: salt }(
                owner,
                votingDelay,
                minVotingDuration,
                maxVotingDuration,
                proposalThreshold,
                quorum,
                votingStrategies,
                authenticators,
                executionStrategiesAddresses
            )
        );

        emit SpaceCreated(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            authenticators,
            executionStrategiesAddresses
        );
    }
}
