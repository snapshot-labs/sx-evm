// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@zodiac/interfaces/IAvatar.sol";
import "../interfaces/IExecutionStrategy.sol";
import "../utils/SpaceManager.sol";

/// @title Execution strategy that executes transactions on an Avatar contract
contract AvatarExecutionStrategy is SpaceManager, IExecutionStrategy {
    error SpaceNotEnabled();
    error TransactionsFailed();

    /// @dev Address of the multisend contract that this contract should use to bundle transactions.
    address public multisend;

    /// @dev Address that this module will pass transactions to.
    address public target;

    constructor(address _owner, address _target, address _multisend, address[] memory _spaces) {
        bytes memory initParams = abi.encode(_owner, _target, _multisend, _spaces);
        setUp(initParams);
    }

    function setUp(bytes memory initParams) public initializer {
        (address _owner, address _target, address _multisend, address[] memory _spaces) = abi.decode(
            initParams,
            (address, address, address, address[])
        );
        __Ownable_init();
        transferOwnership(_owner);
        __SpaceManager_init(_spaces);
        target = _target;
        multisend = _multisend;
    }

    function setTarget(address _target) external onlyOwner {
        target = _target;
    }

    function setMultisend(address _multisend) external onlyOwner {
        multisend = _multisend;
    }

    function execute(ProposalOutcome proposalOutcome, bytes memory executionParams) external override {
        if (spaces[msg.sender] == false) revert SpaceNotEnabled();
        if (proposalOutcome == ProposalOutcome.Accepted) {
            _execute(executionParams);
        }
    }

    function _execute(bytes memory executionParams) internal {
        // bytes memory data = abi.encodeWithSignature("multiSend(bytes)", executionParams);
        // If any transaction fails, the entire batch will fail.

        MetaTransaction[] memory transactions = abi.decode(executionParams, (MetaTransaction[]));
        for (uint256 i = 0; i < transactions.length; i++) {
            bool success = IAvatar(target).execTransactionFromModule(
                transactions[i].to,
                transactions[i].value,
                transactions[i].data,
                transactions[i].operation
            );
            // If any transaction fails, the entire execution will revert
            if (!success) revert TransactionsFailed();
        }
    }
}
