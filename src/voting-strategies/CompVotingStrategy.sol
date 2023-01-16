// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@solidity-bytes-utils/contracts/BytesLib.sol";
import "../interfaces/IVotingStrategy.sol";
import "../interfaces/IComp.sol";
import "../utils/TimestampResolver.sol";

contract CompVotingStrategy is IVotingStrategy, TimestampResolver {
    // solhint-disable no-unused-vars
    function getVotingPower(
        uint256 timestamp,
        address voterAddress,
        bytes memory params,
        bytes memory userParams
    ) external view returns (uint256) {
        address tokenAddress = BytesLib.toAddress(params, 0);
        return uint256(IComp(tokenAddress).getPriorVotes(voterAddress, block.number - 1));
    }
}
