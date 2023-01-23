// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@zodiac/core/Module.sol";
import "../interfaces/IExecutionStrategy.sol";

contract AvatarExecutionStrategy is Module, IExecutionStrategy {
    error AlreadyExecuted();
    uint256 public executed;

  constructor(
    address _owner,
    address _avatar,
    address _target,
    address[] memory _spacesWhitelist
  ) {
    bytes memory initParams = abi.encode(
      _owner,
      _avatar,
      _target,
      _spacesWhitelist
    );
    setUp(initParams);
  }

    function setup(bytes memory initParams) public override initializer {
        (
        address _owner,
        address _avatar,
        address _target,
        address[] memory _spacesWhitelist
        ) = abi.decode(initParams, (address, address, address, address[]));
        __Ownable_init();
        transferOwnership(_owner);
        avatar = _avatar;
        target = _target;
        setUpSnapshotXProposalRelayer(_starknetCore, _l2ExecutionRelayer);

        for (uint256 i = 0; i < _l2SpacesToWhitelist.length; i++) {
        whitelistedSpaces[_l2SpacesToWhitelist[i]] = true;
        }  
    };

    // solhint-disable no-unused-vars
    function execute(ProposalOutcome proposalOutcome, bytes memory executionParams) external override {
        if (executed == 0) {
            executed = 1;
        } else {
            revert AlreadyExecuted();
        }
    }
}