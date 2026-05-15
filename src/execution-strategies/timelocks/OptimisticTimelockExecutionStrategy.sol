// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { OptimisticQuorumExecutionStrategy } from "../OptimisticQuorumExecutionStrategy.sol";
import { SpaceManager } from "../../utils/SpaceManager.sol";
import { MetaTransaction, Proposal, ProposalStatus } from "../../types.sol";
import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title Optimistic Timelock Execution Strategy
/// @notice Used to execute proposal transactions according to a timelock delay.
contract OptimisticTimelockExecutionStrategy is OptimisticQuorumExecutionStrategy, IERC1155Receiver, IERC721Receiver {
    /// @notice Thrown if timelock delay is in the future.
    error TimelockDelayNotMet();

    /// @notice Thrown if the proposal execution payload hash is not queued.
    error ProposalNotQueued();

    /// @notice Thrown if the proposal execution payload hash is already queued.
    error DuplicateExecutionPayloadHash();

    /// @notice Thrown if veto caller is not the veto guardian.
    error OnlyVetoGuardian();

    event TransactionQueued(MetaTransaction transaction, uint256 executionTime);
    event TransactionExecuted(MetaTransaction transaction);

    event OptimisticTimelockExecutionStrategySetUp(
        address owner,
        address vetoGuardian,
        address[] spaces,
        uint256 quorum,
        uint256 timelockDelay
    );

    event VetoGuardianSet(address vetoGuardian, address newVetoGuardian);
    event TimelockDelaySet(uint256 timelockDelay, uint256 newTimelockDelay);
    event ProposalVetoed(bytes32 executionPayloadHash);
    event ProposalQueued(bytes32 executionPayloadHash);
    event ProposalExecuted(bytes32 executionPayloadHash);

    /// @notice The delay in seconds between a proposal being queued and the execution of the proposal.
    uint256 public timelockDelay;

    /// @notice The time at which a proposal can be executed. Indexed by the hash of the proposal execution payload.
    mapping(bytes32 => uint256) public proposalExecutionTime;

    /// @notice Veto guardian is given permission to veto any queued proposal.
    address public vetoGuardian;

    /// @notice Constructor.
    constructor() {
        setUp(abi.encode(address(1), address(1), new address[](0), 0, 0));
    }

    /// @notice Initialization function, should be called immediately after deploying a new proxy to this contract.
    function setUp(bytes memory initParams) public initializer {
        (address _owner, address _vetoGuardian, address[] memory _spaces, uint256 _timelockDelay, uint256 _quorum) = abi
            .decode(initParams, (address, address, address[], uint256, uint256));
        __Ownable_init(_owner);
        vetoGuardian = _vetoGuardian;
        __SpaceManager_init(_spaces);
        __OptimisticQuorumExecutionStrategy_init(_quorum);
        timelockDelay = _timelockDelay;
        emit OptimisticTimelockExecutionStrategySetUp(_owner, _vetoGuardian, _spaces, _quorum, _timelockDelay);
    }

    /// @notice Executes a proposal by queueing its transactions in the timelock. Can only be called by approved spaces.
    function execute(
        uint256 /* proposalId */,
        Proposal memory proposal,
        bool quorumReached,
        bool supportAchieved,
        bytes memory payload
    ) external override onlySpace {
        ProposalStatus proposalStatus = getProposalStatus(proposal, quorumReached, supportAchieved);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }

        if (proposalExecutionTime[proposal.executionPayloadHash] != 0) revert DuplicateExecutionPayloadHash();

        uint256 executionTime = block.timestamp + timelockDelay;
        proposalExecutionTime[proposal.executionPayloadHash] = executionTime;

        MetaTransaction[] memory transactions = abi.decode(payload, (MetaTransaction[]));
        for (uint256 i = 0; i < transactions.length; i++) {
            emit TransactionQueued(transactions[i], executionTime);
        }
        emit ProposalQueued(proposal.executionPayloadHash);
    }

    /// @notice Executes a queued proposal.
    function executeQueuedProposal(bytes memory payload) external {
        bytes32 executionPayloadHash = keccak256(payload);

        uint256 executionTime = proposalExecutionTime[executionPayloadHash];

        if (executionTime == 0) revert ProposalNotQueued();
        if (proposalExecutionTime[executionPayloadHash] > block.timestamp) revert TimelockDelayNotMet();

        proposalExecutionTime[executionPayloadHash] = 0;

        MetaTransaction[] memory transactions = abi.decode(payload, (MetaTransaction[]));
        for (uint256 i = 0; i < transactions.length; i++) {
            bool success;
            if (transactions[i].operation == Enum.Operation.DelegateCall) {
                // solhint-disable-next-line avoid-low-level-calls
                (success, ) = transactions[i].to.delegatecall(transactions[i].data);
            } else {
                (success, ) = transactions[i].to.call{ value: transactions[i].value }(transactions[i].data);
            }
            if (!success) revert ExecutionFailed();

            emit TransactionExecuted(transactions[i]);
        }
        emit ProposalExecuted(executionPayloadHash);
    }

    /// @notice Vetoes a queued proposal.
    function veto(bytes32 executionPayloadHash) external onlyVetoGuardian {
        if (proposalExecutionTime[executionPayloadHash] == 0) revert ProposalNotQueued();

        proposalExecutionTime[executionPayloadHash] = 0;
        emit ProposalVetoed(executionPayloadHash);
    }

    /// @notice Sets the veto guardian.
    function setVetoGuardian(address newVetoGuardian) external onlyOwner {
        emit VetoGuardianSet(vetoGuardian, newVetoGuardian);
        vetoGuardian = newVetoGuardian;
    }

    function setTimelockDelay(uint256 newTimelockDelay) external onlyOwner {
        emit TimelockDelaySet(timelockDelay, newTimelockDelay);
        timelockDelay = newTimelockDelay;
    }

    /// @dev Throws if called by any account other than the veto guardian.
    modifier onlyVetoGuardian() {
        if (msg.sender != vetoGuardian) revert OnlyVetoGuardian();
        _;
    }

    /// @notice Returns the strategy type string.
    function getStrategyType() external pure override returns (string memory) {
        return "OptimisticQuorumTimelock";
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice IERC165 interface support
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
