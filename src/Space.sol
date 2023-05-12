// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { ISpace, ISpaceActions, ISpaceState, ISpaceOwnerActions } from "src/interfaces/ISpace.sol";
import { Choice, FinalizationStatus, IndexedStrategy, Proposal, ProposalStatus, Strategy } from "src/types.sol";
import { IVotingStrategy } from "src/interfaces/IVotingStrategy.sol";
import { IExecutionStrategy } from "src/interfaces/IExecutionStrategy.sol";
import { IProposalValidationStrategy } from "src/interfaces/IProposalValidationStrategy.sol";
import { SXUtils } from "./utils/SXUtils.sol";
import { BitPacker } from "./utils/BitPacker.sol";

/// @title Space Contract
/// @notice The core contract for Snapshot X.
///         A proxy of this contract should be deployed with the Proxy Factory.
contract Space is ISpace, Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    using BitPacker for uint256;
    using SXUtils for IndexedStrategy[];

    /// @dev Placeholder value to indicate the user does not want to update the metadataURI.
    bytes32 private NO_UPDATE_METADATA_URI = "I do not want to update the metadataURI";
    bytes32 private constant NO_UPDATE_METADATA_URI_HASH = keccak256(abi.encodePacked(NO_UPDATE_METADATA_URI));

    /// @dev Placeholder value to indicate the user does not want to update an address.
    address private constant NO_UPDATE_PROPOSAL_STRATEGY = 0x1337133713371337133713371337133713371337;

    /// @dev Placeholder value to indicate the user does not want to update an duration (or, generally, a uint32).
    uint32 private constant NO_UPDATE_DURATION = 2 ** 32 - 1;

    /// @inheritdoc ISpaceState
    uint32 public override maxVotingDuration;
    /// @inheritdoc ISpaceState
    uint32 public override minVotingDuration;
    /// @inheritdoc ISpaceState
    uint256 public override nextProposalId;
    /// @inheritdoc ISpaceState
    uint32 public override votingDelay;
    /// @inheritdoc ISpaceState
    uint256 public override activeVotingStrategies;
    /// @inheritdoc ISpaceState
    mapping(uint8 strategyIndex => Strategy strategy) public override votingStrategies;
    /// @inheritdoc ISpaceState
    uint8 public override nextVotingStrategyIndex;
    /// @inheritdoc ISpaceState
    Strategy public override proposalValidationStrategy;
    /// @inheritdoc ISpaceState
    mapping(address auth => bool allowed) public override authenticators;
    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => Proposal proposal) public override proposals;
    // @inheritdoc ISpaceState
    mapping(uint256 proposalId => mapping(Choice choice => uint256 votePower)) public override votePower;
    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => mapping(address voter => bool hasVoted)) public override voteRegistry;

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

        if (_votingStrategies.length == 0) revert EmptyArray();
        if (_authenticators.length == 0) revert EmptyArray();
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

    // ------------------------------------
    // |                                  |
    // |             SETTERS              |
    // |                                  |
    // ------------------------------------

    /// @inheritdoc ISpaceOwnerActions
    function updateStrategies(
        Strategy calldata _proposalValidationStrategy,
        address[] calldata _authenticatorsToAdd,
        address[] calldata _authenticatorsToRemove,
        Strategy[] calldata _votingStrategiesToAdd,
        string[] calldata _votingStrategyMetadataURIsToAdd,
        uint8[] calldata _votingIndicesToRemove
    ) external override onlyOwner {
        if (_proposalValidationStrategy.addr != NO_UPDATE_PROPOSAL_STRATEGY) {
            _setProposalValidationStrategy(_proposalValidationStrategy);
            emit ProposalValidationStrategyUpdated(_proposalValidationStrategy);
        }

        if (_authenticatorsToAdd.length > 0) {
            _addAuthenticators(_authenticatorsToAdd);
            emit AuthenticatorsAdded(_authenticatorsToAdd);
        }

        if (_authenticatorsToRemove.length > 0) {
            _removeAuthenticators(_authenticatorsToRemove);
            emit AuthenticatorsRemoved(_authenticatorsToRemove);
        }

        if (_votingStrategiesToAdd.length > 0) {
            _addVotingStrategies(_votingStrategiesToAdd);
            emit VotingStrategiesAdded(_votingStrategiesToAdd, _votingStrategyMetadataURIsToAdd);
        }

        if (_votingIndicesToRemove.length > 0) {
            _removeVotingStrategies(_votingIndicesToRemove);
            emit VotingStrategiesRemoved(_votingIndicesToRemove);
        }
    }

    /// @inheritdoc ISpaceOwnerActions
    function updateSettings(
        uint32 _minVotingDuration,
        uint32 _maxVotingDuration,
        uint32 _votingDelay,
        string calldata _metadataURI
    ) external override onlyOwner {
        if ((_minVotingDuration != NO_UPDATE_DURATION) && (_maxVotingDuration != NO_UPDATE_DURATION)) {
            // Check that min and max VotingDuration are valid
            // We don't use the internal `_setMinVotingDuration` and `_setMaxVotingDuration` functions because
            // it would revert when `_minVotingDuration > maxVotingDuration` (when the new `_min` is
            // bigger than the current `max`).
            if (_minVotingDuration > _maxVotingDuration) revert InvalidDuration(_minVotingDuration, _maxVotingDuration);

            minVotingDuration = _minVotingDuration;
            emit MinVotingDurationUpdated(_minVotingDuration);

            maxVotingDuration = _maxVotingDuration;
            emit MaxVotingDurationUpdated(_maxVotingDuration);
        } else if (_minVotingDuration != NO_UPDATE_DURATION) {
            _setMinVotingDuration(_minVotingDuration);
            emit MinVotingDurationUpdated(_minVotingDuration);
        } else if (_maxVotingDuration != NO_UPDATE_DURATION) {
            _setMaxVotingDuration(_maxVotingDuration);
            emit MaxVotingDurationUpdated(_maxVotingDuration);
        }
        // else: nothing to update

        if (_votingDelay != NO_UPDATE_DURATION) {
            _setVotingDelay(_votingDelay);
            emit VotingDelayUpdated(_votingDelay);
        }

        if (keccak256(abi.encodePacked(_metadataURI)) != NO_UPDATE_METADATA_URI_HASH) {
            emit MetadataURIUpdated(_metadataURI);
        }
    }

    /// @dev Gates access to whitelisted authenticators only.
    modifier onlyAuthenticator() {
        if (authenticators[msg.sender] != true) revert AuthenticatorNotWhitelisted();
        _;
    }

    // ------------------------------------
    // |                                  |
    // |             GETTERS              |
    // |                                  |
    // ------------------------------------

    /// @inheritdoc ISpaceState
    function getProposalStatus(uint256 proposalId) external view override returns (ProposalStatus) {
        Proposal memory proposal = proposals[proposalId];
        _assertProposalExists(proposal);
        return
            proposal.executionStrategy.getProposalStatus(
                proposal,
                votePower[proposalId][Choice.For],
                votePower[proposalId][Choice.Against],
                votePower[proposalId][Choice.Abstain]
            );
    }

    // ------------------------------------
    // |                                  |
    // |             CORE                 |
    // |                                  |
    // ------------------------------------

    /// @inheritdoc ISpaceActions
    function propose(
        address author,
        string calldata metadataURI,
        Strategy calldata executionStrategy,
        bytes calldata userProposalValidationParams
    ) external override onlyAuthenticator {
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
            activeVotingStrategies
        );

        proposals[nextProposalId] = proposal;
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
    ) external override onlyAuthenticator {
        Proposal memory proposal = proposals[proposalId];
        _assertProposalExists(proposal);
        if (block.timestamp >= proposal.maxEndTimestamp) revert VotingPeriodHasEnded();
        if (block.timestamp < proposal.startTimestamp) revert VotingPeriodHasNotStarted();
        if (proposal.finalizationStatus != FinalizationStatus.Pending) revert ProposalFinalized();
        if (voteRegistry[proposalId][voter]) revert UserAlreadyVoted();

        uint256 votingPower = _getCumulativePower(
            voter,
            proposal.snapshotTimestamp,
            userVotingStrategies,
            proposal.activeVotingStrategies
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
        Proposal storage proposal = proposals[proposalId];
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
        Proposal storage proposal = proposals[proposalId];
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
    ) external override onlyAuthenticator {
        Proposal storage proposal = proposals[proposalId];
        if (author != proposal.author) revert InvalidCaller();
        if (block.timestamp >= proposal.startTimestamp) revert VotingDelayHasPassed();

        proposal.executionPayloadHash = keccak256(executionStrategy.params);
        proposal.executionStrategy = IExecutionStrategy(executionStrategy.addr);

        emit ProposalUpdated(proposalId, executionStrategy, metadataURI);
    }

    // ------------------------------------
    // |                                  |
    // |            INTERNAL              |
    // |                                  |
    // ------------------------------------

    /// @dev Only the Space owner can authorize an upgrade to this contract.
    // solhint-disable-next-line no-empty-blocks
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

    /// @dev Adds an array of voting strategies.
    function _addVotingStrategies(Strategy[] memory _votingStrategies) internal {
        uint256 cachedActiveVotingStrategies = activeVotingStrategies;
        uint8 cachedNextVotingStrategyIndex = nextVotingStrategyIndex;
        if (cachedNextVotingStrategyIndex >= 256 - _votingStrategies.length) revert ExceedsStrategyLimit();
        for (uint256 i = 0; i < _votingStrategies.length; i++) {
            if (_votingStrategies[i].addr == address(0)) revert ZeroAddress();
            cachedActiveVotingStrategies = cachedActiveVotingStrategies.setBit(cachedNextVotingStrategyIndex, true);
            votingStrategies[cachedNextVotingStrategyIndex] = _votingStrategies[i];
            cachedNextVotingStrategyIndex++;
        }
        activeVotingStrategies = cachedActiveVotingStrategies;
        nextVotingStrategyIndex = cachedNextVotingStrategyIndex;
    }

    /// @dev Removes an array of voting strategies, specified by their indices.
    function _removeVotingStrategies(uint8[] memory _votingStrategyIndices) internal {
        for (uint8 i = 0; i < _votingStrategyIndices.length; i++) {
            activeVotingStrategies = activeVotingStrategies.setBit(_votingStrategyIndices[i], false);
        }
        // There must always be at least one active voting strategy.
        if (activeVotingStrategies == 0) revert NoActiveVotingStrategies();
    }

    /// @dev Adds an array of authenticators.
    function _addAuthenticators(address[] memory _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = true;
        }
    }

    /// @dev Removes an array of authenticators.
    function _removeAuthenticators(address[] memory _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = false;
        }
        // TODO: should we check that there are still authenticators left? same for other setters..
    }

    /// @dev Reverts if `msg.sender` is not in the list of whitelisted authenticators.
    function _assertValidAuthenticator() internal view {
        if (authenticators[msg.sender] != true) revert AuthenticatorNotWhitelisted();
    }

    /// @dev Reverts if a specified proposal does not exist.
    function _assertProposalExists(Proposal memory proposal) internal pure {
        // startTimestamp cannot be set to 0 when a proposal is created,
        // so if proposal.startTimestamp is 0 it means this proposal does not exist
        // and hence `proposalId` is invalid.
        if (proposal.startTimestamp == 0) revert InvalidProposal();
    }

    /// @dev Returns the cumulative voting power of a user over a set of voting strategies.
    function _getCumulativePower(
        address userAddress,
        uint32 timestamp,
        IndexedStrategy[] memory userStrategies,
        uint256 allowedStrategies
    ) internal returns (uint256) {
        // Ensure there are no duplicates to avoid an attack where people double count a strategy.
        userStrategies.assertNoDuplicateIndices();

        uint256 totalVotingPower;
        for (uint256 i = 0; i < userStrategies.length; ++i) {
            uint8 strategyIndex = userStrategies[i].index;

            // Check that the strategy is allowed for this proposal.
            if (!allowedStrategies.isBitSet(strategyIndex)) {
                revert InvalidStrategyIndex(strategyIndex);
            }

            Strategy memory strategy = votingStrategies[strategyIndex];

            totalVotingPower += IVotingStrategy(strategy.addr).getVotingPower(
                timestamp,
                userAddress,
                strategy.params,
                userStrategies[i].params
            );
        }
        return totalVotingPower;
    }
}
