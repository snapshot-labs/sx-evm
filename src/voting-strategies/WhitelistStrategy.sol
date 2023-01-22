// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../interfaces/IVotingStrategy.sol";

contract WhitelistStrategy is IVotingStrategy {
    mapping(address => uint256) public members;

    struct Member {
        address addy;
        uint256 vp;
    }

    constructor(Member[] memory _members) {
        for (uint256 i = 0; i < _members.length; i++) {
            Member memory member = _members[i];
            members[member.addy] = member.vp;
        }
    }

    function getVotingPower(
        uint32 /* timestamp */,
        address voterAddress,
        bytes calldata /* params */,
        bytes calldata /* userParams */
    ) external override returns (uint256) {
        return members[voterAddress];
    }
}
