// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IComp {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}