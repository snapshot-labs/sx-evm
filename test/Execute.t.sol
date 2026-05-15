// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SpaceTest } from "./utils/Space.t.sol";
import { IndexedStrategy, ProposalStatus, Strategy, UpdateSettingsCalldata } from "../src/types.sol";
import { VanillaExecutionStrategy } from "../src/execution-strategies/VanillaExecutionStrategy.sol";

contract ExecuteTest is SpaceTest {
    function testExecute() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration() + 1000);
        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(proposalId);
        _tryExecute(proposalId, executionStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Executed));
    }

    function testExecuteInvalidProposal() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        uint256 invalidProposalId = proposalId + 1;
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecuteInvalidProposalExpectRevert(
            invalidProposalId,
            executionStrategy.params,
            abi.encodeWithSelector(InvalidProposal.selector)
        );
    }

    function testExecuteAlreadyExecuted() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());
        _tryExecute(proposalId, executionStrategy.params);

        _tryExecuteExpectRevert(
            proposalId,
            executionStrategy.params,
            abi.encodeWithSelector(ProposalFinalized.selector)
        );
    }

    function testExecuteMinDurationNotElapsed() public {
        space.updateSettings(
            UpdateSettingsCalldata(
                100,
                NO_UPDATE_UINT32,
                NO_UPDATE_UINT32,
                NO_UPDATE_STRING,
                NO_UPDATE_STRING,
                NO_UPDATE_STRATEGY,
                NO_UPDATE_STRING,
                NO_UPDATE_ADDRESSES,
                NO_UPDATE_ADDRESSES,
                NO_UPDATE_STRATEGIES,
                NO_UPDATE_STRINGS,
                NO_UPDATE_UINT8S
            )
        );
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);

        _tryExecuteExpectRevert(
            proposalId,
            executionStrategy.params,
            abi.encodeWithSelector(InvalidProposalStatus.selector, ProposalStatus.VotingPeriod)
        );

        vm.roll(vm.getBlockNumber() + space.minVotingDuration());
        _tryExecute(proposalId, executionStrategy.params);
    }

    function testExecuteQuorumNotReachedYet() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));

        _tryExecute(proposalId, executionStrategy.params);
        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.VotingPeriod));
    }

    function testExecuteQuorumNotReachedAtAll() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        _tryExecute(proposalId, executionStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Rejected));
    }

    function testExecuteWithAgainstVote() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        _vote(author, proposalId, 0, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        // Against vote -- _tryExecute processes attestations but proposal should not be executed
        _tryExecute(proposalId, executionStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Rejected));
    }

    function testExecuteWithAbstainVote() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        _vote(author, proposalId, 2, userVotingStrategies, voteMetadataURI);
        vm.roll(vm.getBlockNumber() + space.maxVotingDuration());

        // Abstain vote -- _tryExecute processes attestations but proposal should not be executed
        _tryExecute(proposalId, executionStrategy.params);

        assertEq(uint8(space.getProposalStatus(proposalId)), uint8(ProposalStatus.Rejected));
    }

    function testExecuteInvalidPayload() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, executionStrategy, new bytes(0));
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);

        _tryExecuteExpectRevert(proposalId, new bytes(4242), abi.encodeWithSelector(InvalidPayload.selector));
    }

    function testExecuteInvalidExecutionStrategy() public {
        uint256 proposalId = _createProposal(author, proposalMetadataURI, Strategy(address(space), ""), new bytes(0));
        vm.expectRevert();
        _vote(author, proposalId, 1, userVotingStrategies, voteMetadataURI);
    }

    function testGetStrategyType() external view {
        assertEq(vanillaExecutionStrategy.getStrategyType(), "SimpleQuorumVanilla");
    }
}
