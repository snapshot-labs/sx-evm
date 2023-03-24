// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { ISpace, ISpaceActions, ISpaceState, ISpaceOwnerActions } from "src/interfaces/ISpace.sol";
import { Choice, FinalizationStatus, IndexedStrategy, Proposal, ProposalStatus, Strategy } from "src/types.sol";
import { IExecutionStrategy } from "src/interfaces/IExecutionStrategy.sol";
import { IProposalValidationStrategy } from "src/interfaces/IProposalValidationStrategy.sol";
import { GetCumulativePower } from "./utils/GetCumulativePower.sol";

/**
 * @author  SnapshotLabs
 * @title   Space Contract.
 * @notice  Logic and bookkeeping contract.
 */
contract Space is ISpace, Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    using GetCumulativePower for address;

    // Maximum duration a proposal can last.
    uint32 public maxVotingDuration;
    // Minimum duration a proposal can last.
    uint32 public minVotingDuration;
    // Next proposal nonce, increased by one every time a new proposal is created.
    uint256 public nextProposalId;
    // Delay between when the proposal is created and when the voting period starts for this proposal.
    uint32 public votingDelay;

    // Array of available voting strategies that users can use to determine their voting power.
    /// @dev This needs to be an array because a mapping would limit a space to only one use per
    ///      voting strategy contract.
    Strategy[] public votingStrategies;

    // The proposal validation contract.
    Strategy public proposalValidationStrategy;

    // Mapping of allowed authenticators.
    mapping(address auth => bool allowed) private authenticators;
    // Mapping of all `Proposal`s of this space (past and present).
    mapping(uint256 proposalId => Proposal proposal) private proposalRegistry;
    // Mapping used to know if a voter already voted on a specific proposal. Here to prevent double voting.
    mapping(uint256 proposalId => mapping(address voter => bool hasVoted)) private voteRegistry;
    // Mapping used to check the current voting power in favor of a `Choice` for a specific proposal.
    mapping(uint256 proposalId => mapping(Choice choice => uint256 votePower)) private votePower;

    /// @inheritdoc ISpaceActions
    function initialize(
        address _owner,
        uint32 _votingDelay,
        uint32 _minVotingDuration,
        uint32 _maxVotingDuration,
        Strategy memory _proposalValidationStrategy,
        string memory _metadataURI,
        Strategy[] memory _votingStrategies,
        string[] memory _votingStrategyMetadataURIs,
        address[] memory _authenticators
    ) public initializer {
        __Ownable_init();
        transferOwnership(_owner);
        _setMaxVotingDuration(_maxVotingDuration);
        _setMinVotingDuration(_minVotingDuration);
        _setProposalValidationStrategy(_proposalValidationStrategy);
        _setVotingDelay(_votingDelay);
        _addVotingStrategies(_votingStrategies);
        _addAuthenticators(_authenticators);

        nextProposalId = 1;

        emit SpaceCreated(
            address(this),
            _owner,
            _votingDelay,
            _minVotingDuration,
            _maxVotingDuration,
            _proposalValidationStrategy,
            _metadataURI,
            _votingStrategies,
            _votingStrategyMetadataURIs,
            _authenticators
        );
    }

    /// @inheritdoc ISpaceOwnerActions
    function setMaxVotingDuration(uint32 _maxVotingDuration) external override onlyOwner {
        _setMaxVotingDuration(_maxVotingDuration);
        emit MaxVotingDurationUpdated(_maxVotingDuration);
    }

    /// @inheritdoc ISpaceOwnerActions
    function setMinVotingDuration(uint32 _minVotingDuration) external override onlyOwner {
        _setMinVotingDuration(_minVotingDuration);
        emit MinVotingDurationUpdated(_minVotingDuration);
    }

    /// @inheritdoc ISpaceOwnerActions
    function setMetadataURI(string calldata _metadataURI) external override onlyOwner {
        emit MetadataURIUpdated(_metadataURI);
    }

    /// @inheritdoc ISpaceOwnerActions
    function setProposalValidationStrategy(Strategy calldata _proposalValidationStrategy) external override onlyOwner {
        _setProposalValidationStrategy(_proposalValidationStrategy);
        emit ProposalValidationStrategyUpdated(_proposalValidationStrategy);
    }

    /// @inheritdoc ISpaceOwnerActions
    function setVotingDelay(uint32 _votingDelay) external override onlyOwner {
        _setVotingDelay(_votingDelay);
        emit VotingDelayUpdated(_votingDelay);
    }

    /// @inheritdoc ISpaceOwnerActions
    function addVotingStrategies(
        Strategy[] calldata _votingStrategies,
        string[] calldata votingStrategyMetadataURIs
    ) external override onlyOwner {
        _addVotingStrategies(_votingStrategies);
        emit VotingStrategiesAdded(_votingStrategies, votingStrategyMetadataURIs);
    }

    /// @inheritdoc ISpaceOwnerActions
    function removeVotingStrategies(uint8[] calldata _votingStrategyIndices) external override onlyOwner {
        _removeVotingStrategies(_votingStrategyIndices);
        emit VotingStrategiesRemoved(_votingStrategyIndices);
    }

    /// @inheritdoc ISpaceOwnerActions
    function addAuthenticators(address[] calldata _authenticators) external override onlyOwner {
        _addAuthenticators(_authenticators);
        emit AuthenticatorsAdded(_authenticators);
    }

    /// @inheritdoc ISpaceOwnerActions
    function removeAuthenticators(address[] calldata _authenticators) external override onlyOwner {
        _removeAuthenticators(_authenticators);
        emit AuthenticatorsRemoved(_authenticators);
    }

    /// @inheritdoc ISpaceState
    function getProposal(uint256 proposalId) external view override returns (Proposal memory) {
        Proposal memory proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);
        return proposalRegistry[proposalId];
    }

    /// @inheritdoc ISpaceState
    function getProposalStatus(uint256 proposalId) public view override returns (ProposalStatus) {
        Proposal memory proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);
        return
            proposal.executionStrategy.getProposalStatus(
                proposal,
                votePower[proposalId][Choice.For],
                votePower[proposalId][Choice.Against],
                votePower[proposalId][Choice.Abstain]
            );
    }

    /// @inheritdoc ISpaceState
    function hasVoted(uint256 proposalId, address voter) external view override returns (bool) {
        Proposal memory proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);

        return voteRegistry[proposalId][voter];
    }

    /// @inheritdoc ISpaceActions
    function propose(
        address author,
        string calldata metadataURI,
        Strategy calldata executionStrategy,
        bytes calldata userProposalValidationParams
    ) external override {
        _assertValidAuthenticator();

        // Casting to `uint32` is fine because this gives us until year ~2106.
        uint32 snapshotTimestamp = uint32(block.timestamp);

        if (
            !IProposalValidationStrategy(proposalValidationStrategy.addr).validate(
                author,
                proposalValidationStrategy.params,
                userProposalValidationParams
            )
        ) revert FailedToPassProposalValidation();

        uint32 startTimestamp = snapshotTimestamp + votingDelay;
        uint32 minEndTimestamp = startTimestamp + minVotingDuration;
        uint32 maxEndTimestamp = startTimestamp + maxVotingDuration;

        // The execution payload is the params of the supplied execution strategy struct.
        bytes32 executionPayloadHash = keccak256(executionStrategy.params);

        Proposal memory proposal = Proposal(
            snapshotTimestamp,
            startTimestamp,
            minEndTimestamp,
            maxEndTimestamp,
            executionPayloadHash,
            IExecutionStrategy(executionStrategy.addr),
            author,
            FinalizationStatus.Pending,
            votingStrategies
        );

        proposalRegistry[nextProposalId] = proposal;
        emit ProposalCreated(nextProposalId, author, proposal, metadataURI, executionStrategy.params);

        nextProposalId++;
    }

    /// @inheritdoc ISpaceActions
    function vote(
        address voter,
        uint256 proposalId,
        Choice choice,
        IndexedStrategy[] calldata userVotingStrategies,
        string calldata metadataURI
    ) external override {
        _assertValidAuthenticator();

        Proposal memory proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);
        if (block.timestamp >= proposal.maxEndTimestamp) revert VotingPeriodHasEnded();
        if (block.timestamp < proposal.startTimestamp) revert VotingPeriodHasNotStarted();
        if (proposal.finalizationStatus != FinalizationStatus.Pending) revert ProposalFinalized();
        if (voteRegistry[proposalId][voter]) revert UserHasAlreadyVoted();

        uint256 votingPower = voter.getCumulativePower(
            proposal.snapshotTimestamp,
            userVotingStrategies,
            proposal.votingStrategies
        );
        if (votingPower == 0) revert UserHasNoVotingPower();
        votePower[proposalId][choice] += votingPower;
        voteRegistry[proposalId][voter] = true;

        if (bytes(metadataURI).length == 0) {
            emit VoteCast(proposalId, voter, choice, votingPower);
        } else {
            emit VoteCastWithMetadata(proposalId, voter, choice, votingPower, metadataURI);
        }
    }

    /// @inheritdoc ISpaceActions
    function execute(uint256 proposalId, bytes calldata executionPayload) external override nonReentrant {
        Proposal storage proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);

        // We add reentrancy protection here to prevent this function being re-entered by the execution strategy.
        // We cannot use the Checks-Effects-Interactions pattern because the proposal status is checked inside
        // the execution strategy (so essentially forced to do Checks-Interactions-Effects).
        proposal.executionStrategy.execute(
            proposal,
            votePower[proposalId][Choice.For],
            votePower[proposalId][Choice.Against],
            votePower[proposalId][Choice.Abstain],
            executionPayload
        );

        proposal.finalizationStatus = FinalizationStatus.Executed;

        emit ProposalExecuted(proposalId);
    }

    /// @inheritdoc ISpaceOwnerActions
    function cancel(uint256 proposalId) external override onlyOwner {
        Proposal storage proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);
        if (proposal.finalizationStatus != FinalizationStatus.Pending) revert ProposalFinalized();
        proposal.finalizationStatus = FinalizationStatus.Cancelled;
        emit ProposalCancelled(proposalId);
    }

    /// @inheritdoc ISpaceActions
    function updateProposal(
        address author,
        uint256 proposalId,
        Strategy calldata executionStrategy,
        string calldata metadataURI
    ) external override {
        _assertValidAuthenticator();

        Proposal storage proposal = proposalRegistry[proposalId];
        if (author != proposal.author) revert InvalidCaller();
        if (block.timestamp >= proposal.startTimestamp) revert VotingDelayHasPassed();

        proposal.executionPayloadHash = keccak256(executionStrategy.params);
        proposal.executionStrategy = IExecutionStrategy(executionStrategy.addr);

        emit ProposalUpdated(proposalId, executionStrategy, metadataURI);
    }

    /// @dev Authorizes an upgrade to a new implementation via requiring the call to be made by the `owner`.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Sets the maximum voting duration.
    function _setMaxVotingDuration(uint32 _maxVotingDuration) internal {
        if (_maxVotingDuration < minVotingDuration) revert InvalidDuration(minVotingDuration, _maxVotingDuration);
        maxVotingDuration = _maxVotingDuration;
    }

    /// @dev Sets the minimum voting duration.
    function _setMinVotingDuration(uint32 _minVotingDuration) internal {
        if (_minVotingDuration > maxVotingDuration) revert InvalidDuration(_minVotingDuration, maxVotingDuration);
        minVotingDuration = _minVotingDuration;
    }

    /// @dev Sets the proposal validation strategy.
    function _setProposalValidationStrategy(Strategy memory _proposalValidationStrategy) internal {
        proposalValidationStrategy = _proposalValidationStrategy;
    }

    /// @dev Sets the voting delay.
    function _setVotingDelay(uint32 _votingDelay) internal {
        votingDelay = _votingDelay;
    }

    /// @dev Adds an array of voting strategies to the whitelist.
    function _addVotingStrategies(Strategy[] memory _votingStrategies) internal {
        if (_votingStrategies.length == 0) revert EmptyArray();
        for (uint256 i = 0; i < _votingStrategies.length; i++) {
            // A voting strategy set to 0 is used to indicate that the voting strategy is no longer active,
            // so we need to prevent the user from adding a null invalid strategy address.
            if (_votingStrategies[i].addr == address(0)) revert InvalidStrategyAddress();
            votingStrategies.push(_votingStrategies[i]);
        }
    }

    /// @dev Removes an array of voting strategies from the whitelist via their index in the `votingStrategy` array.
    function _removeVotingStrategies(uint8[] memory _votingStrategyIndices) internal {
        if (_votingStrategyIndices.length == 0) revert EmptyArray();
        for (uint8 i = 0; i < _votingStrategyIndices.length; i++) {
            votingStrategies[_votingStrategyIndices[i]].addr = address(0);
            votingStrategies[_votingStrategyIndices[i]].params = new bytes(0);
        }
    }

    /// @dev Adds an array of authenticators to the whitelist.
    function _addAuthenticators(address[] memory _authenticators) internal {
        if (_authenticators.length == 0) revert EmptyArray();
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = true;
        }
    }

    /// @dev Removes an array of authenticators from the whitelist.
    function _removeAuthenticators(address[] memory _authenticators) internal {
        if (_authenticators.length == 0) revert EmptyArray();
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = false;
        }
    }

    /// @dev Reverts if the caller is not a whitelisted authenticator.
    function _assertValidAuthenticator() internal view {
        if (authenticators[msg.sender] != true) revert AuthenticatorNotWhitelisted(msg.sender);
    }

    /// @dev Reverts if a queried proposal is uninitialized.
    function _assertProposalExists(Proposal memory proposal) internal pure {
        // `proposal.startTimestamp` cannot be set to 0 when a proposal is created,
        // so if proposal.startTimestamp is 0 it means this proposal does not exist.
        if (proposal.startTimestamp == 0) revert InvalidProposal();
    }
}
