// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./utils/Space.t.sol";
import "../src/types.sol";

contract UpdateProposalMetadataTest is SpaceTest {
    string newMetadataUri = "Testing123";

    function setUp() public virtual override {
        super.setUp();

        // Set the votingDelay to 10.
        votingDelay = 10;
        space.setVotingDelay(votingDelay);
    }

    function _updateProposalMetadata(address _author, uint256 _proposalId, string memory _metadataUri) public {
        vanillaAuthenticator.authenticate(
            address(space),
            UPDATE_PROPOSAL_METADATA_SELECTOR,
            abi.encode(_author, _proposalId, _metadataUri)
        );
    }

    function testUpdateProposalMetadata() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, executionStrategy, userVotingStrategies);

        vm.expectEmit(true, true, true, true);
        emit ProposalMetadataUpdated(proposalId, newMetadataUri);

        // Update metadata.
        _updateProposalMetadata(author, proposalId, newMetadataUri);

        // Fast forward and finish the proposal to ensure everything is still working properly.
        vm.warp(block.timestamp + votingDelay);
        _vote(author, proposalId, Choice.For, userVotingStrategies);
        space.execute(proposalId, executionStrategy.params);
    }

    function testUpdateProposalMetadataAfterDelay() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, executionStrategy, userVotingStrategies);
        vm.warp(block.timestamp + votingDelay);

        vm.expectRevert(VotingDelayHasPassed.selector);
        // Try to update metadata. Should fail.
        _updateProposalMetadata(author, proposalId, newMetadataUri);
    }

    function testUpdateProposalMetadataInvalidCaller() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, executionStrategy, userVotingStrategies);

        vm.expectRevert(InvalidCaller.selector);
        _updateProposalMetadata(address(42), proposalId, newMetadataUri);
    }

    function testUpdateProposalMetadataUnauthenticated() public {
        uint256 proposalId = _createProposal(author, proposalMetadataUri, executionStrategy, userVotingStrategies);

        vm.expectRevert(abi.encodeWithSelector(AuthenticatorNotWhitelisted.selector, address(this)));
        space.updateProposalMetadata(author, proposalId, newMetadataUri);
    }
}
