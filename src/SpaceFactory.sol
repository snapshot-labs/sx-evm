// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Space.sol";
import "./interfaces/ISpaceFactory.sol";
import "./types.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title   Space Factory
 * @notice  A contract to deploy and track spaces
 * @author  Snapshot Labs
 */
contract SpaceFactory is ISpaceFactory {
    address public immutable masterSpace;

    constructor(address _masterSpace) {
        masterSpace = _masterSpace;
    }

    function createSpace(
        address controller,
        uint32 votingDelay,
        uint32 minVotingDuration,
        uint32 maxVotingDuration,
        uint256 proposalThreshold,
        uint256 quorum,
        string calldata metadataUri,
        Strategy[] calldata votingStrategies,
        address[] calldata authenticators,
        address[] calldata executionStrategies,
        bytes32 salt
    ) external override {
        try
            new ERC1967Proxy{ salt: salt }(
                masterSpace,
                ""
            )
        returns (ERC1967Proxy space) {
            address(space).call(
                abi.encodeWithSignature(
                    "initialize(address,uint32,uint32,uint32,uint256,uint256,(address,bytes)[],address[],address[])",
                    controller,
                    votingDelay,
                    minVotingDuration,
                    maxVotingDuration,
                    proposalThreshold,
                    quorum,
                    metadataUri,
                    votingStrategies,
                    authenticators,
                    executionStrategies
                )
            );
            emit SpaceCreated(
                address(space),
                controller,
                votingDelay,
                minVotingDuration,
                maxVotingDuration,
                proposalThreshold,
                quorum,
                metadataUri,
                votingStrategies,
                authenticators,
                executionStrategies
            );
        } catch {
            revert SpaceCreationFailed();
        }
    }
}
