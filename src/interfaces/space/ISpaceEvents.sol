// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "src/types.sol";

interface ISpaceEvents {
    event ProposalCreated(
        uint256 nextProposalNonce,
        address proposerAddress,
        Proposal proposal,
        string metadataUri,
        bytes executionParams
    );
}
