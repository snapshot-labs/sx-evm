// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Space.sol";
import "./interfaces/ISpaceFactory.sol";
import "./types.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title   Immutable Space Proxy Factory
 * @notice  A contract to deploy and track proxies of a master Space contract
 * @author  Snapshot Labs
 */
contract SpaceFactory is ISpaceFactory {
    bytes4 private constant INITIALIZE_SELECTOR =
        bytes4(
            keccak256("initialize(address,uint32,uint32,uint32,uint256,(address,bytes)[],address[],(address,bytes)[])")
        );

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
        string calldata metadataUri,
        Strategy[] calldata votingStrategies,
        address[] calldata authenticators,
        Strategy[] calldata executionStrategies,
        bytes32 salt
    ) external override {
        try
            new ERC1967Proxy{ salt: salt }(
                masterSpace,
                abi.encodeWithSelector(
                    INITIALIZE_SELECTOR,
                    controller,
                    votingDelay,
                    minVotingDuration,
                    maxVotingDuration,
                    proposalThreshold,
                    votingStrategies,
                    authenticators,
                    executionStrategies
                )
            )
        returns (ERC1967Proxy space) {
            emit SpaceCreated(
                address(space),
                controller,
                votingDelay,
                minVotingDuration,
                maxVotingDuration,
                proposalThreshold,
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
