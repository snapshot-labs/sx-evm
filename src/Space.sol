// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC4824 } from "src/interfaces/IERC4824.sol";
import { ISpace, ISpaceActions, ISpaceState, ISpaceOwnerActions } from "src/interfaces/ISpace.sol";
import {
    FinalizationStatus,
    IndexedStrategy,
    Proposal,
    ProposalStatus,
    Strategy,
    UpdateSettingsCalldata,
    InitializeCalldata,
    TRUE,
    FALSE
} from "src/types.sol";
import { IVotingStrategy } from "src/interfaces/IVotingStrategy.sol";
import { IExecutionStrategy } from "src/interfaces/IExecutionStrategy.sol";
import { IProposalValidationStrategy } from "src/interfaces/IProposalValidationStrategy.sol";
import { SXUtils } from "./utils/SXUtils.sol";
import { BitPacker } from "./utils/BitPacker.sol";

// Inco imports
import { euint256, ebool, e, inco } from "@inco/lightning/src/Lib.sol";
import { DecryptionAttestation } from "@inco/lightning/src/lightning-parts/DecryptionAttester.types.sol";
import { asBool } from "@inco/lightning/src/shared/TypeUtils.sol";

/// @title Space Contract
/// @notice The core contract for Snapshot X with Inco confidential voting.
///         A proxy of this contract should be deployed with the Proxy Factory.
contract Space is ISpace, Initializable, IERC4824, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    using BitPacker for uint256;
    using SXUtils for IndexedStrategy[];
    using e for bytes;
    using e for euint256;
    using e for ebool;

    /// @dev Placeholder value to indicate the user does not want to update a string.
    /// @dev Evaluates to: `0xf2cda9b13ed04e585461605c0d6e804933ca828111bd94d4e6a96c75e8b048ba`.
    bytes32 private constant NO_UPDATE_HASH = keccak256(abi.encodePacked("No update"));

    /// @dev Placeholder value to indicate the user does not want to update an address.
    /// @dev Evaluates to: `0xf2cda9b13ed04e585461605c0d6e804933ca8281`.
    address private constant NO_UPDATE_ADDRESS = address(bytes20(keccak256(abi.encodePacked("No update"))));

    /// @dev Placeholder value to indicate the user does not want to update a uint32.
    /// @dev Evaluates to: `0xf2cda9b1`.
    uint32 private constant NO_UPDATE_UINT32 = uint32(bytes4(keccak256(abi.encodePacked("No update"))));

    /// @inheritdoc IERC4824
    string public daoURI;
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
    mapping(address auth => uint256 allowed) public override authenticators;
    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => Proposal proposal) public override proposals;
    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => mapping(address voter => uint256 hasVoted)) public override voteRegistry;

    // Vote tallies stored as encrypted values. 0=Against, 1=For, 2=Abstain.
    // Private: no one can read running tallies.
    mapping(uint256 proposalId => mapping(uint8 choice => euint256)) private votePower;

    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => euint256) public override encryptedIsQuorumReached;
    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => euint256) public override encryptedIsSupportAchieved;

    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => bool) public override isQuorumReached;
    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => bool) public override isSupportAchieved;

    /// @dev Allow the contract to receive ETH for Inco confidential compute fees.
    receive() external payable {}

    /// @dev Explicit funding entrypoint.
    function fund() external payable {}

    /// @inheritdoc ISpaceActions
    function initialize(InitializeCalldata calldata input) external override initializer {
        if (input.votingStrategies.length == 0) revert EmptyArray();
        if (input.authenticators.length == 0) revert EmptyArray();
        if (input.votingStrategies.length != input.votingStrategyMetadataURIs.length) revert ArrayLengthMismatch();

        __Ownable_init(input.owner);
        _setDaoURI(input.daoURI);
        _setMaxVotingDuration(input.maxVotingDuration);
        _setMinVotingDuration(input.minVotingDuration);
        _setProposalValidationStrategy(input.proposalValidationStrategy);
        _setVotingDelay(input.votingDelay);
        _addVotingStrategies(input.votingStrategies);
        _addAuthenticators(input.authenticators);

        nextProposalId = 1;

        emit SpaceCreated(address(this), input);
    }

    // ------------------------------------
    // |                                  |
    // |             SETTERS              |
    // |                                  |
    // ------------------------------------

    /// @inheritdoc ISpaceOwnerActions
    // solhint-disable-next-line code-complexity
    function updateSettings(UpdateSettingsCalldata calldata input) external override onlyOwner {
        if ((input.minVotingDuration != NO_UPDATE_UINT32) && (input.maxVotingDuration != NO_UPDATE_UINT32)) {
            if (input.minVotingDuration > input.maxVotingDuration) {
                revert InvalidDuration(input.minVotingDuration, input.maxVotingDuration);
            }

            minVotingDuration = input.minVotingDuration;
            emit MinVotingDurationUpdated(input.minVotingDuration);

            maxVotingDuration = input.maxVotingDuration;
            emit MaxVotingDurationUpdated(input.maxVotingDuration);
        } else if (input.minVotingDuration != NO_UPDATE_UINT32) {
            _setMinVotingDuration(input.minVotingDuration);
            emit MinVotingDurationUpdated(input.minVotingDuration);
        } else if (input.maxVotingDuration != NO_UPDATE_UINT32) {
            _setMaxVotingDuration(input.maxVotingDuration);
            emit MaxVotingDurationUpdated(input.maxVotingDuration);
        }

        if (input.votingDelay != NO_UPDATE_UINT32) {
            _setVotingDelay(input.votingDelay);
            emit VotingDelayUpdated(input.votingDelay);
        }

        if (keccak256(abi.encodePacked(input.metadataURI)) != NO_UPDATE_HASH) {
            emit MetadataURIUpdated(input.metadataURI);
        }

        if (keccak256(abi.encodePacked(input.daoURI)) != NO_UPDATE_HASH) {
            _setDaoURI(input.daoURI);
            emit DaoURIUpdated(input.daoURI);
        }

        if (input.proposalValidationStrategy.addr != NO_UPDATE_ADDRESS) {
            _setProposalValidationStrategy(input.proposalValidationStrategy);
            emit ProposalValidationStrategyUpdated(
                input.proposalValidationStrategy,
                input.proposalValidationStrategyMetadataURI
            );
        }

        if (input.authenticatorsToAdd.length > 0) {
            _addAuthenticators(input.authenticatorsToAdd);
            emit AuthenticatorsAdded(input.authenticatorsToAdd);
        }

        if (input.authenticatorsToRemove.length > 0) {
            _removeAuthenticators(input.authenticatorsToRemove);
            emit AuthenticatorsRemoved(input.authenticatorsToRemove);
        }

        if (input.votingStrategiesToAdd.length > 0) {
            if (input.votingStrategiesToAdd.length != input.votingStrategyMetadataURIsToAdd.length) {
                revert ArrayLengthMismatch();
            }
            _addVotingStrategies(input.votingStrategiesToAdd);
            emit VotingStrategiesAdded(input.votingStrategiesToAdd, input.votingStrategyMetadataURIsToAdd);
        }

        if (input.votingStrategiesToRemove.length > 0) {
            _removeVotingStrategies(input.votingStrategiesToRemove);
            emit VotingStrategiesRemoved(input.votingStrategiesToRemove);
        }
    }

    /// @dev Gates access to whitelisted authenticators only.
    modifier onlyAuthenticator() {
        if (authenticators[msg.sender] == FALSE) revert AuthenticatorNotWhitelisted();
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
                isQuorumReached[proposalId],
                isSupportAchieved[proposalId]
            );
    }

    /// @inheritdoc ISpaceState
    function getQuorumAndSupportHandles(
        uint256 proposalId
    ) external view override returns (euint256 quorumHandle, euint256 supportHandle) {
        return (encryptedIsQuorumReached[proposalId], encryptedIsSupportAchieved[proposalId]);
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
        if (
            !IProposalValidationStrategy(proposalValidationStrategy.addr).validate(
                author,
                proposalValidationStrategy.params,
                userProposalValidationParams
            )
        ) revert FailedToPassProposalValidation();

        uint32 startBlockNumber = uint32(block.number) + votingDelay;
        uint32 minEndBlockNumber = startBlockNumber + minVotingDuration;
        uint32 maxEndBlockNumber = startBlockNumber + maxVotingDuration;

        bytes32 executionPayloadHash = keccak256(executionStrategy.params);

        Proposal memory proposal = Proposal(
            author,
            startBlockNumber,
            IExecutionStrategy(executionStrategy.addr),
            minEndBlockNumber,
            maxEndBlockNumber,
            FinalizationStatus.Pending,
            executionPayloadHash,
            activeVotingStrategies
        );

        proposals[nextProposalId] = proposal;

        // Initialize quorum/support encrypted handles to "false" so tryExecute can attest
        // even before any vote is cast.
        euint256 initialQuorum = e.asEuint256(0);
        initialQuorum.allowThis();
        initialQuorum.allow(msg.sender);
        initialQuorum.allow(author);
        encryptedIsQuorumReached[nextProposalId] = initialQuorum;

        euint256 initialSupport = e.asEuint256(0);
        initialSupport.allowThis();
        initialSupport.allow(msg.sender);
        initialSupport.allow(author);
        encryptedIsSupportAchieved[nextProposalId] = initialSupport;

        emit ProposalCreated(nextProposalId, author, proposal, metadataURI, executionStrategy.params);

        nextProposalId++;
    }

    /// @inheritdoc ISpaceActions
    function vote(
        address voter,
        uint256 proposalId,
        bytes calldata ciphertext,
        IndexedStrategy[] calldata userVotingStrategies,
        string calldata metadataURI
    ) external override onlyAuthenticator {
        Proposal memory proposal = proposals[proposalId];
        _assertProposalExists(proposal);
        if (block.number >= proposal.maxEndBlockNumber) revert VotingPeriodHasEnded();
        if (block.number < proposal.startBlockNumber) revert VotingPeriodHasNotStarted();
        if (proposal.finalizationStatus != FinalizationStatus.Pending) revert ProposalFinalized();
        if (voteRegistry[proposalId][voter] != FALSE) revert UserAlreadyVoted();

        voteRegistry[proposalId][voter] = TRUE;

        uint256 votingPower = _getCumulativePower(
            voter,
            proposal.startBlockNumber,
            userVotingStrategies,
            proposal.activeVotingStrategies
        );
        if (votingPower == 0) revert UserHasNoVotingPower();

        // --- CONFIDENTIAL SECTION: Process encrypted vote ---

        // 1. Create encrypted handle from the user's ciphertext
        bytes memory ciphertextMem = ciphertext;
        euint256 userChoice = ciphertextMem.newEuint256(voter);

        // 2. Determine which bucket this vote goes to (all comparisons are encrypted)
        ebool isAgainst = userChoice.eq(uint256(0));
        ebool isFor = userChoice.eq(uint256(1));
        ebool isAbstain = userChoice.eq(uint256(2));

        // 3. Encrypt the voting power
        euint256 encryptedPower = e.asEuint256(votingPower);

        // 4. Conditionally add power to each bucket using select (encrypted ternary)

        // Against votes (index 0)
        euint256 existingAgainst = _getOrZero(proposalId, 0);
        euint256 newAgainst = isAgainst.select(existingAgainst.add(encryptedPower), existingAgainst);
        newAgainst.allowThis();
        newAgainst.allow(msg.sender);
        votePower[proposalId][0] = newAgainst;

        // For votes (index 1)
        euint256 existingFor = _getOrZero(proposalId, 1);
        euint256 newFor = isFor.select(existingFor.add(encryptedPower), existingFor);
        newFor.allowThis();
        newFor.allow(msg.sender);
        votePower[proposalId][1] = newFor;

        // Abstain votes (index 2)
        euint256 existingAbstain = _getOrZero(proposalId, 2);
        euint256 newAbstain = isAbstain.select(existingAbstain.add(encryptedPower), existingAbstain);
        newAbstain.allowThis();
        newAbstain.allow(msg.sender);
        votePower[proposalId][2] = newAbstain;

        // 5. Compute encrypted quorum and support flags
        uint256 quorumValue = proposal.executionStrategy.getQuorum();
        ebool quorumReachedFlag = newFor.add(newAbstain).ge(quorumValue);
        ebool supportAchievedFlag = newFor.gt(newAgainst);

        // 6. Store encrypted results as euint256 (cast from ebool)
        euint256 encQuorum = e.asEuint256(quorumReachedFlag);
        euint256 encSupport = e.asEuint256(supportAchievedFlag);

        encQuorum.allowThis();
        encQuorum.allow(msg.sender);
        encQuorum.allow(proposal.author);
        encryptedIsQuorumReached[proposalId] = encQuorum;

        encSupport.allowThis();
        encSupport.allow(msg.sender);
        encSupport.allow(proposal.author);
        encryptedIsSupportAchieved[proposalId] = encSupport;

        // 7. Grant execution strategy access to vote tallies
        newAgainst.allow(address(proposal.executionStrategy));
        newFor.allow(address(proposal.executionStrategy));
        newAbstain.allow(address(proposal.executionStrategy));

        // --- END CONFIDENTIAL SECTION ---

        if (bytes(metadataURI).length == 0) {
            emit VoteCast(proposalId, voter, votingPower);
        } else {
            emit VoteCastWithMetadata(proposalId, voter, votingPower, metadataURI);
        }
    }

    /// @inheritdoc ISpaceActions
    function tryExecute(
        uint256 proposalId,
        bytes calldata executionPayload,
        DecryptionAttestation memory quorumAttestation,
        bytes[] memory quorumSignatures,
        DecryptionAttestation memory supportAttestation,
        bytes[] memory supportSignatures
    ) external override {
        Proposal storage proposal = proposals[proposalId];
        _assertProposalExists(proposal);
        if (proposal.finalizationStatus != FinalizationStatus.Pending) revert ProposalFinalized();

        // 1. Verify covalidator signatures on both attestations
        require(
            inco.incoVerifier().isValidDecryptionAttestation(quorumAttestation, quorumSignatures),
            "Invalid quorum attestation"
        );
        require(
            inco.incoVerifier().isValidDecryptionAttestation(supportAttestation, supportSignatures),
            "Invalid support attestation"
        );

        // 2. Verify the attestation handles match our stored encrypted values
        require(
            euint256.unwrap(encryptedIsQuorumReached[proposalId]) == quorumAttestation.handle,
            "Quorum handle mismatch"
        );
        require(
            euint256.unwrap(encryptedIsSupportAchieved[proposalId]) == supportAttestation.handle,
            "Support handle mismatch"
        );

        // 3. Extract decrypted boolean results
        bool quorumPassed = asBool(quorumAttestation.value);
        bool supportPassed = asBool(supportAttestation.value);

        // 4. Store the decrypted results
        isQuorumReached[proposalId] = quorumPassed;
        isSupportAchieved[proposalId] = supportPassed;

        // 5. Execute if both conditions are met
        if (quorumPassed && supportPassed) {
            _execute(proposalId, executionPayload);
        }
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
        _assertProposalExists(proposal);
        if (proposal.finalizationStatus != FinalizationStatus.Pending) revert ProposalFinalized();
        if (author != proposal.author) revert InvalidCaller();
        if (block.number >= proposal.startBlockNumber) revert VotingDelayHasPassed();

        proposal.executionPayloadHash = keccak256(executionStrategy.params);
        proposal.executionStrategy = IExecutionStrategy(executionStrategy.addr);

        emit ProposalUpdated(proposalId, executionStrategy, metadataURI);
    }

    // ------------------------------------
    // |                                  |
    // |            INTERNAL              |
    // |                                  |
    // ------------------------------------

    /// @dev Internal execution, called only after attestation verification.
    function _execute(uint256 proposalId, bytes calldata executionPayload) internal nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        _assertProposalExists(proposal);
        Proposal memory cachedProposal = proposal;
        if (cachedProposal.executionPayloadHash != keccak256(executionPayload)) revert InvalidPayload();
        if (cachedProposal.finalizationStatus != FinalizationStatus.Pending) revert ProposalFinalized();

        proposal.finalizationStatus = FinalizationStatus.Executed;

        proposal.executionStrategy.execute(
            proposalId,
            cachedProposal,
            isQuorumReached[proposalId],
            isSupportAchieved[proposalId],
            executionPayload
        );

        emit ProposalExecuted(proposalId);
    }

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
    function _setProposalValidationStrategy(Strategy calldata _proposalValidationStrategy) internal {
        proposalValidationStrategy = _proposalValidationStrategy;
    }

    /// @dev Sets the voting delay.
    function _setVotingDelay(uint32 _votingDelay) internal {
        votingDelay = _votingDelay;
    }

    /// @dev Sets the DAO URI.
    function _setDaoURI(string calldata _daoURI) internal {
        daoURI = _daoURI;
    }

    /// @dev Adds an array of voting strategies.
    function _addVotingStrategies(Strategy[] calldata _votingStrategies) internal {
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
    function _removeVotingStrategies(uint8[] calldata _votingStrategyIndices) internal {
        for (uint8 i = 0; i < _votingStrategyIndices.length; i++) {
            activeVotingStrategies = activeVotingStrategies.setBit(_votingStrategyIndices[i], false);
        }
        if (activeVotingStrategies == 0) revert NoActiveVotingStrategies();
    }

    /// @dev Adds an array of authenticators.
    function _addAuthenticators(address[] calldata _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = TRUE;
        }
    }

    /// @dev Removes an array of authenticators.
    function _removeAuthenticators(address[] calldata _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = FALSE;
        }
    }

    /// @dev Reverts if a specified proposal does not exist.
    function _assertProposalExists(Proposal memory proposal) internal pure {
        if (proposal.executionPayloadHash == 0) revert InvalidProposal();
    }

    /// @dev Returns existing encrypted vote tally or zero if not yet initialized.
    function _getOrZero(uint256 proposalId, uint8 choice) internal returns (euint256) {
        if (euint256.unwrap(votePower[proposalId][choice]) == bytes32(0)) {
            euint256 zero = e.asEuint256(0);
            zero.allowThis();
            return zero;
        }
        return votePower[proposalId][choice];
    }

    /// @dev Returns the cumulative voting power of a user over a set of voting strategies.
    function _getCumulativePower(
        address userAddress,
        uint32 blockNumber,
        IndexedStrategy[] calldata userStrategies,
        uint256 allowedStrategies
    ) internal view returns (uint256) {
        userStrategies.assertNoDuplicateIndicesCalldata();

        uint256 totalVotingPower;
        for (uint256 i = 0; i < userStrategies.length; ++i) {
            uint8 strategyIndex = userStrategies[i].index;

            if (!allowedStrategies.isBitSet(strategyIndex)) {
                revert InvalidStrategyIndex(strategyIndex);
            }

            Strategy memory strategy = votingStrategies[strategyIndex];

            totalVotingPower += IVotingStrategy(strategy.addr).getVotingPower(
                blockNumber,
                userAddress,
                strategy.params,
                userStrategies[i].params
            );
        }
        return totalVotingPower;
    }
}
