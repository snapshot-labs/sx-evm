// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import "./Space.sol";
import "./interfaces/ISpaceFactory.sol";
import "./types.sol";

/**
 * @author  SnapshotLabs
 * @title   Space Factory Contract.
 */
contract SpaceFactory is ISpaceFactory {
    Space[] public spaces;

    function createSpace(
        address owner,
        uint32 votingDelay,
        uint32 minVotingDuration,
        uint32 maxVotingDuration,
        uint256 proposalThreshold,
        uint256 quorum,
        Strategy[] calldata votingStrategies,
        address[] calldata authenticators,
        address[] calldata executionStrategiesAddresses
    ) external {
        spaces.push(
            new Space(
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
