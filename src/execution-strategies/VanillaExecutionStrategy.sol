// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./SimpleQuorumExecutionStrategy.sol";

contract VanillaExecutionStrategy is SimpleQuorumExecutionStrategy {
    error InvalidProposalStatus(ProposalStatus status);
    uint256 numExecuted;

    // solhint-disable no-unused-vars
    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory params,
        bytes memory payload
    ) external override {
        ProposalStatus proposalStatus = getProposalStatus(proposal, params, votesFor, votesAgainst, votesAbstain);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }
        numExecuted++;
    }
}
