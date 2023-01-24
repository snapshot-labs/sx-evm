// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@zodiac/core/Module.sol";
import "../interfaces/IExecutionStrategy.sol";
import "../utils/SpaceManager.sol";


contract AvatarExecutionStrategy is SpaceManager, IExecutionStrategy {
    error SpaceNotEnabled();

    /// @dev Address of the multisend contract that this contract should use to bundle transactions.
    address public multisend;

    /// @dev Address that this module will pass transactions to.
    address public target;

    constructor(address _owner, address _target, address[] memory _spaces) {
        bytes memory initParams = abi.encode(_owner, _target, _spaces);
        setUp(initParams);
    }

    function setUp(bytes memory initParams) public initializer {
        (address _owner, address _target, address[] memory _spaces) = abi.decode(
            initParams,
            (address, address, address[])
        );
        __Ownable_init();
        transferOwnership(_owner);
        target = _target;
        enableSpaces(_spaces);
    }

    function setTarget(address _target) external onlyOwner {
        target = _target;
    }

    // solhint-disable no-unused-vars
    function execute(ProposalOutcome proposalOutcome, bytes memory executionParams) external override {
      if (spaces[msg.sender] == false) revert SpaceNotEnabled();

      bool success = IAvatar(target).execTransactionFromModule(multisend, value, data, operation);

    }
}
