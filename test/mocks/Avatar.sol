// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

contract Avatar {
    address public module;

    receive() external payable {}

    function enableModule(address _module) external {
        module = _module;
    }

    function disableModule(address, address) external {
        module = address(0);
    }

    function isModuleEnabled(address _module) external view returns (bool) {
        if (module == _module) {
            return true;
        } else {
            return false;
        }
    }

    function execTransactionFromModule(
        address payable to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external returns (bool success) {
        require(msg.sender == module, "Not authorized");
        if (operation == 1) (success, ) = to.delegatecall(data);
        else (success, ) = to.call{ value: value }(data);
    }

    function getModulesPaginated(
        address,
        uint256 pageSize
    ) external view returns (address[] memory array, address next) {
        // Init array with max page size
        array = new address[](pageSize);

        array[0] = module;
        next = module;
    }
}
