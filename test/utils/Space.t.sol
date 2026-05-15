// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IncoTest } from "@inco/lightning/src/test/IncoTest.sol";
import { GasSnapshot } from "forge-gas-snapshot/GasSnapshot.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Space } from "../../src/Space.sol";
import { VanillaAuthenticator } from "../../src/authenticators/VanillaAuthenticator.sol";
import { VanillaVotingStrategy } from "../../src/voting-strategies/VanillaVotingStrategy.sol";
import { VanillaExecutionStrategy } from "../../src/execution-strategies/VanillaExecutionStrategy.sol";
import {
    VanillaProposalValidationStrategy
} from "../../src/proposal-validation-strategies/VanillaProposalValidationStrategy.sol";
import { ISpaceEvents } from "../../src/interfaces/space/ISpaceEvents.sol";
import { ISpaceErrors } from "../../src/interfaces/space/ISpaceErrors.sol";
import { IExecutionStrategyErrors } from "../../src/interfaces/execution-strategies/IExecutionStrategyErrors.sol";
import { Strategy, IndexedStrategy, InitializeCalldata, TRUE, FALSE } from "../../src/types.sol";

// Inco imports for test helpers
import { euint256, inco } from "@inco/lightning/src/Lib.sol";
import { DecryptionAttestation } from "@inco/lightning/src/lightning-parts/DecryptionAttester.types.sol";
import { AllowanceProof } from "@inco/lightning/src/lightning-parts/AccessControl/AdvancedAccessControl.types.sol";

// solhint-disable-next-line max-states-count
abstract contract SpaceTest is IncoTest, GasSnapshot, ISpaceEvents, ISpaceErrors, IExecutionStrategyErrors {
    bytes4 internal constant PROPOSE_SELECTOR = bytes4(keccak256("propose(address,string,(address,bytes),bytes)"));
    bytes4 internal constant VOTE_SELECTOR = bytes4(keccak256("vote(address,uint256,bytes,(uint8,bytes)[],string)"));
    bytes4 internal constant UPDATE_PROPOSAL_SELECTOR =
        bytes4(keccak256("updateProposal(address,uint256,(address,bytes),string)"));
    bytes4 internal constant OWNABLE_UNAUTHORIZED_ACCOUNT_SELECTOR =
        bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
    bytes4 internal constant OWNABLE_INVALID_OWNER_SELECTOR = bytes4(keccak256("OwnableInvalidOwner(address)"));
    bytes4 internal constant INVALID_INITIALIZATION_SELECTOR = bytes4(keccak256("InvalidInitialization()"));

    Space internal masterSpace;
    Space internal space;
    VanillaVotingStrategy internal vanillaVotingStrategy;
    VanillaAuthenticator internal vanillaAuthenticator;
    VanillaExecutionStrategy internal vanillaExecutionStrategy;
    VanillaProposalValidationStrategy internal vanillaProposalValidationStrategy;

    uint256 public constant AUTHOR_KEY = 1234;
    uint256 public constant VOTER_KEY = 5678;
    uint256 public constant UNAUTHORIZED_KEY = 4321;

    string internal voteMetadataURI = "Hi";

    // Address of the meta transaction relayer (mana)
    address public relayer = address(this);
    // Space owner — must be address(this) so the test contract can call onlyOwner functions directly
    address public spaceOwner = address(this);
    address public author = vm.addr(AUTHOR_KEY);
    address public voter = vm.addr(VOTER_KEY);
    address public unauthorized = vm.addr(UNAUTHORIZED_KEY);

    // Initial whitelisted modules set in the space
    Strategy[] internal votingStrategies;
    Strategy internal proposalValidationStrategy;
    address[] internal authenticators;
    Strategy[] internal executionStrategies;

    // Empty array used to edit settings
    Strategy[] internal NO_UPDATE_STRATEGIES;
    address[] internal NO_UPDATE_ADDRESSES;
    string[] internal NO_UPDATE_STRINGS;
    uint8[] internal NO_UPDATE_UINT8S;

    // Vanity address
    address internal NO_UPDATE_ADDRESS = address(bytes20(keccak256(abi.encodePacked("No update"))));
    Strategy internal NO_UPDATE_STRATEGY = Strategy(NO_UPDATE_ADDRESS, new bytes(0));
    uint32 internal NO_UPDATE_UINT32 = uint32(bytes4(keccak256(abi.encodePacked("No update"))));
    string internal NO_UPDATE_STRING = "No update";

    // Initial space parameters
    uint32 public votingDelay;
    uint32 public minVotingDuration;
    uint32 public maxVotingDuration;
    uint32 public quorum;

    // Default voting and execution strategy setups
    IndexedStrategy[] public userVotingStrategies;
    Strategy public executionStrategy;

    // Dummy metadata URIs
    string public daoURI = "SOC Test DAO";
    string public spaceMetadataURI = "SOC Test Space";
    string public proposalMetadataURI = "SOC Test Proposal";
    string[] public votingStrategyMetadataURIs;
    string public proposalValidationStrategyMetadataURI;

    // Empty proof for decryption attestation requests
    AllowanceProof internal emptyProof;

    function setUp() public virtual override {
        super.setUp(); // REQUIRED: deploys mocked Inco infra
        vm.stopPrank(); // IncoTest.setUp() leaves a startPrank active

        masterSpace = new Space();

        quorum = 1;

        vanillaVotingStrategy = new VanillaVotingStrategy();
        vanillaAuthenticator = new VanillaAuthenticator();
        vanillaExecutionStrategy = new VanillaExecutionStrategy(spaceOwner, quorum);
        vanillaProposalValidationStrategy = new VanillaProposalValidationStrategy();

        votingDelay = 0;
        minVotingDuration = 0;
        maxVotingDuration = 1000;
        votingStrategies.push(Strategy(address(vanillaVotingStrategy), new bytes(0)));
        votingStrategyMetadataURIs.push("VanillaVotingStrategy");
        authenticators.push(address(vanillaAuthenticator));
        executionStrategies.push(Strategy(address(vanillaExecutionStrategy), new bytes(0)));
        userVotingStrategies.push(IndexedStrategy(0, new bytes(0)));
        executionStrategy = Strategy(address(vanillaExecutionStrategy), new bytes(0));
        proposalValidationStrategy = Strategy(address(vanillaProposalValidationStrategy), new bytes(0));
        space = Space(
            payable(
                address(
                    new ERC1967Proxy(
                        address(masterSpace),
                        abi.encodeWithSelector(
                            Space.initialize.selector,
                            InitializeCalldata(
                                spaceOwner,
                                votingDelay,
                                minVotingDuration,
                                maxVotingDuration,
                                proposalValidationStrategy,
                                proposalValidationStrategyMetadataURI,
                                daoURI,
                                spaceMetadataURI,
                                votingStrategies,
                                votingStrategyMetadataURIs,
                                authenticators
                            )
                        )
                    )
                )
            )
        );

        // Fund the space for Inco confidential compute fees
        vm.deal(address(space), 10 ether);
        // Discard setup logs; tests should process only logs emitted during test actions.
        vm.recordLogs();
    }

    /// @dev Process only newly-emitted Inco operations by resetting the log recorder after each flush.
    function _processAllOperations() internal {
        processAllOperations();
        vm.recordLogs();
    }

    function _createProposal(
        address _author,
        string memory _metadataURI,
        Strategy memory _executionStrategy,
        bytes memory userProposalValidationParams
    ) internal returns (uint256) {
        vanillaAuthenticator.authenticate(
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(_author, _metadataURI, _executionStrategy, userProposalValidationParams)
        );

        return space.nextProposalId() - 1;
    }

    /// @dev Casts an encrypted vote. choiceValue: 0=Against, 1=For, 2=Abstain
    function _vote(
        address _voter,
        uint256 _proposalId,
        uint256 _choiceValue,
        IndexedStrategy[] memory _userVotingStrategies,
        string memory _voteMetadataURI
    ) internal {
        bytes memory ciphertext = fakePrepareEuint256Ciphertext(_choiceValue, _voter, address(space));
        vanillaAuthenticator.authenticate(
            address(space),
            VOTE_SELECTOR,
            abi.encode(_voter, _proposalId, ciphertext, _userVotingStrategies, _voteMetadataURI)
        );
        _processAllOperations();
    }

    /// @dev Executes a proposal via tryExecute with mock attestations.
    function _prepareTryExecuteAttestations(
        uint256 _proposalId
    )
        internal
        returns (
            DecryptionAttestation memory qAttest,
            bytes[] memory qSigs,
            DecryptionAttestation memory sAttest,
            bytes[] memory sSigs
        )
    {
        _processAllOperations();

        bytes32 qHandleRaw = euint256.unwrap(space.encryptedIsQuorumReached(_proposalId));
        bytes32 sHandleRaw = euint256.unwrap(space.encryptedIsSupportAchieved(_proposalId));

        HandleWithProof memory qHandle = HandleWithProof({ handle: qHandleRaw, proof: emptyProof });
        HandleWithProof memory sHandle = HandleWithProof({ handle: sHandleRaw, proof: emptyProof });

        (qAttest, qSigs) = getDecryptionAttestation(address(space), qHandle);
        (sAttest, sSigs) = getDecryptionAttestation(address(space), sHandle);
    }

    /// @dev Executes a proposal via tryExecute with mock attestations.
    function _tryExecute(uint256 _proposalId, bytes memory _payload) internal {
        (
            DecryptionAttestation memory qAttest,
            bytes[] memory qSigs,
            DecryptionAttestation memory sAttest,
            bytes[] memory sSigs
        ) = _prepareTryExecuteAttestations(_proposalId);

        space.tryExecute(_proposalId, _payload, qAttest, qSigs, sAttest, sSigs);
    }

    function _tryExecuteExpectRevert(uint256 _proposalId, bytes memory _payload, bytes memory _revertData) internal {
        (
            DecryptionAttestation memory qAttest,
            bytes[] memory qSigs,
            DecryptionAttestation memory sAttest,
            bytes[] memory sSigs
        ) = _prepareTryExecuteAttestations(_proposalId);
        vm.expectRevert(_revertData);
        space.tryExecute(_proposalId, _payload, qAttest, qSigs, sAttest, sSigs);
    }

    function _tryExecuteExpectAnyRevert(uint256 _proposalId, bytes memory _payload) internal {
        (
            DecryptionAttestation memory qAttest,
            bytes[] memory qSigs,
            DecryptionAttestation memory sAttest,
            bytes[] memory sSigs
        ) = _prepareTryExecuteAttestations(_proposalId);
        vm.expectRevert();
        space.tryExecute(_proposalId, _payload, qAttest, qSigs, sAttest, sSigs);
    }

    function _tryExecuteInvalidProposalExpectRevert(
        uint256 _proposalId,
        bytes memory _payload,
        bytes memory _revertData
    ) internal {
        DecryptionAttestation memory emptyAttestation = DecryptionAttestation({
            handle: bytes32(0),
            value: bytes32(0)
        });
        bytes[] memory noSigs = new bytes[](0);
        vm.expectRevert(_revertData);
        space.tryExecute(_proposalId, _payload, emptyAttestation, noSigs, emptyAttestation, noSigs);
    }

    function _expectOnlyOwnerRevert(address caller) internal {
        vm.expectRevert(abi.encodeWithSelector(OWNABLE_UNAUTHORIZED_ACCOUNT_SELECTOR, caller));
    }

    function _expectInvalidOwnerRevert() internal {
        vm.expectRevert(abi.encodeWithSelector(OWNABLE_INVALID_OWNER_SELECTOR, address(0)));
    }

    function _expectInvalidInitializationRevert() internal {
        vm.expectRevert(INVALID_INITIALIZATION_SELECTOR);
    }
}
