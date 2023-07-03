// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface ICompTimelock {
    /// @notice Msg.sender accepts admin status.
    function acceptAdmin() external;

    /// @notice Queue a transaction to be executed after a delay.
    /// @param target The address of the contract to call.
    /// @param value The amount of Ether to send.
    /// @param signature The function signature to call.
    /// @param data The calldata to send.
    /// @param eta The timestamp at which to execute the transaction, in seconds.
    /// @return The transaction hash.
    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external returns (bytes32);

    /// @notice Execute a queued transaction.
    /// @param target The address of the contract to call.
    /// @param value The amount of Ether to send.
    /// @param signature The function signature to call.
    /// @param data The calldata to send.
    /// @param eta The timestamp at which to execute the transaction, in seconds.
    /// @return The transaction return data.
    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external payable returns (bytes memory);

    /// @notice Cancel a queued transaction.
    /// @param target The address of the contract to call.
    /// @param value The amount of Ether to send.
    /// @param signature The function signature to call.
    /// @param data The calldata to send.
    /// @param eta The timestamp at which to execute the transaction, in seconds.
    function cancelTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external;

    function setDelay(uint delay) external;

    function GRACE_PERIOD() external view returns (uint);

    function MINIMUM_DELAY() external view returns (uint);

    function MAXIMUM_DELAY() external view returns (uint);

    function delay() external view returns (uint);

    function queuedTransactions(bytes32 hash) external view returns (bool);
}
