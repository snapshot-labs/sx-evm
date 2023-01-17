// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../interfaces/IVotingStrategy.sol";

contract VanillaVotingStrategy is IVotingStrategy {
    function getVotingPower(
        uint256 /* timestamp */,
        address /* voterAddress */,
        bytes memory /* params */,
        bytes memory /* userParams */
    ) external pure override returns (uint256) {
        return 1;
    }
}
