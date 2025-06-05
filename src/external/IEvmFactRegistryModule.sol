// SPDX-License-Identifier: GPL-3.0
/* solhint-disable */
pragma solidity ^0.8.27;

interface IEvmFactRegistryModule {
    struct BlockHeaderProof {
        uint256 mmrId;
        uint128 mmrSize;
        uint256 mmrLeafIndex;
        bytes32[] mmrPeaks;
        bytes32[] mmrInclusionProof;
        bytes blockHeaderRlp;
    }

    enum BlockHeaderField {
        PARENT_HASH, // 0
        OMMERS_HASH, // 1
        BENEFICIARY, // 2
        STATE_ROOT, // 3
        RECEIPTS_ROOT, // 4
        TRANSACTIONS_ROOT, // 5
        LOGS_BLOOM, // 6 - not supported
        DIFFICULTY, // 7
        NUMBER, // 8 - not supported
        GAS_LIMIT, // 9
        GAS_USED, // 10
        TIMESTAMP, // 11
        EXTRA_DATA, // 12
        MIX_HASH, // 13
        NONCE // 14
    }

    struct BlockHeader {
        /// @dev Bitmask of saved fields (3 bits)
        uint16 savedFields;
        mapping(BlockHeaderField => bytes32) fields;
    }

    enum AccountField {
        NONCE,
        BALANCE,
        STORAGE_ROOT,
        CODE_HASH,
        APE_FLAGS,
        APE_FIXED,
        APE_SHARES,
        APE_DEBT,
        APE_DELEGATE
    }

    struct Account {
        /// @dev Bitmask of saved fields (5 bits)
        /// @dev First 4 bits are for NONCE, BALANCE, STORAGE_ROOT, CODE_HASH
        /// @dev 5th bit (2^4) is for all ApeChain fields so either all ApeChain fields are saved or none
        uint8 savedFields;
        mapping(AccountField => bytes32) fields;
    }

    struct StorageSlot {
        bytes32 value;
        bool exists;
    }

    struct EvmFactRegistryModuleStorage {
        mapping(uint256 chainId => mapping(address account => mapping(uint256 blockNumber => Account))) accountField;
        mapping(uint256 chainId => mapping(address account => mapping(uint256 blockNumber => mapping(bytes32 slot => StorageSlot)))) accountStorageSlotValues;
        mapping(uint256 chainId => mapping(uint256 timestamp => uint256 blockNumber)) timestampToBlockNumber;
        mapping(uint256 chainId => mapping(uint256 blockNumber => BlockHeader)) blockHeader;
    }

    function APECHAIN_SHARE_PRICE_ADDRESS() external view returns (address);

    function APECHAIN_SHARE_PRICE_SLOT() external view returns (bytes32);

    // =============== Functions for End Users (Reads proven values) ============== //

    /// @notice Fetches block header field (e.g. block hash, state root or timestamp) of a block with a given block number on a given chain id.
    /// @notice Returns (true, value) if the field is saved, (false, 0) otherwise.
    function headerFieldSafe(
        uint256 chainId,
        uint256 blockNumber,
        BlockHeaderField field
    ) external view returns (bool, bytes32);

    /// @notice Returns block header field (e.g. block hash, state root or timestamp) of a block with a given block number on a given chain id.
    /// @notice Reverts with "STORAGE_PROOF_HEADER_FIELD_NOT_SAVED" if the field is not saved.
    function headerField(uint256 chainId, uint256 blockNumber, BlockHeaderField field) external view returns (bytes32);

    /// @notice Fetches account field (e.g. nonce, balance or storage root) of a given account, at a given block number on a given chain id.
    /// @notice Returns (true, value) if the field is saved, (false, 0) otherwise.
    function accountFieldSafe(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        AccountField field
    ) external view returns (bool, bytes32);

    /// @notice Returns account field (e.g. nonce, balance or storage root) of a given account, at a given block number on a given chain id.
    /// @notice Reverts with "STORAGE_PROOF_ACCOUNT_FIELD_NOT_SAVED" if the field is not saved.
    function accountField(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        AccountField field
    ) external view returns (bytes32);

    /// @notice Fetches value of a given storage slot of a given account, at a given block number on a given chain id.
    /// @notice Returns (true, value) if the slot is saved, (false, 0) otherwise.
    function storageSlotSafe(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        bytes32 slot
    ) external view returns (bool, bytes32);

    /// @notice Returns value of a given storage slot of a given account, at a given block number on a given chain id.
    /// @notice Reverts with "STORAGE_PROOF_SLOT_NOT_SAVED" if the slot is not saved.
    function storageSlot(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        bytes32 slot
    ) external view returns (bytes32);

    /// @notice Finds block number with a biggest timestamp that is less than or equal to the given timestamp.
    /// @notice In other words, it answers what was the latest block at a given timestamp (including block with equal timestamp).
    /// @notice Returns (true, block number) if the timestamp is saved, (false, 0) otherwise.
    function timestampSafe(uint256 chainId, uint256 timestamp) external view returns (bool, uint256);

    /// @notice Returns block number with a biggest timestamp that is less than or equal to the given timestamp.
    /// @notice In other words, it answers what was the latest block at a given timestamp (including block with equal timestamp).
    /// @notice Reverts with "STORAGE_PROOF_TIMESTAMP_NOT_SAVED" if the timestamp is not saved.
    function timestamp(uint256 chainId, uint256 timestamp) external view returns (uint256);

    /// @notice Fetches the ApeChain's share price at a given block number.
    /// @notice Returns (true, share price) if the share price is saved for the given block number, (false, 0) otherwise.
    /// @notice Reverts with "STORAGE_PROOF_NOT_APECHAIN" if the given chain id does not support ApeChain-like account balances. TODO: add link
    function getApechainSharePriceSafe(uint256 chainId, uint256 blockNumber) external view returns (bool, uint256);

    /// @notice Returns the ApeChain's share price at a given block number.
    /// @notice Reverts with "STORAGE_PROOF_SHARE_PRICE_NOT_SAVED" if the share price is not saved for the given block number.
    /// @notice Reverts with "STORAGE_PROOF_NOT_APECHAIN" if the given chain id does not support ApeChain-like account balances. TODO: add link
    function getApechainSharePrice(uint256 chainId, uint256 blockNumber) external view returns (uint256);

    // ====================== Proving (Saves verified values) ===================== //

    /// @notice Verifies the headerProof and saves selected fields in the satellite.
    /// @notice Saved fields can be read with `headerFieldSafe` and `headerField` functions.
    /// @param headerFieldsToSave Bitmask of fields to save. i-th bit corresponds to i-th field in `BlockHeaderField` enum.
    function proveHeader(uint256 chainId, uint16 headerFieldsToSave, BlockHeaderProof calldata headerProof) external;

    /// @notice Verifies the accountTrieProof and saves selected fields in the satellite.
    /// @notice Saved fields can be read with `accountFieldSafe` and `accountField` functions.
    /// @notice Requires desired block's STATE_ROOT to be proven first with `proveHeader` function.
    /// @notice Additionally, if chainId is ApeChain and BALANCE bit is set, ApeChain's share price also has to be proven before calling this function.
    /// @notice To prove share price, storage slot with index `APECHAIN_SHARE_PRICE_SLOT` of account `APECHAIN_SHARE_PRICE_ADDRESS` at desired block has to be proven first with `proveStorage` function.
    /// @param accountFieldsToSave Bitmask of fields to save. First 4 bits correspond to NONCE, BALANCE, STORAGE_ROOT and CODE_HASH fields. Last bit (2^4) is responsible for all ApeChain fields, i.e. APE_FLAGS, APE_FIXED, APE_SHARES, APE_DEBT, APE_DELEGATE.
    function proveAccount(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        uint8 accountFieldsToSave,
        bytes calldata accountTrieProof
    ) external;

    /// @notice Verifies the storageSlotMptProof and saves the storage slot value in the satellite.
    /// @notice Saved value can be read with `storageSlotSafe` and `storageSlot` functions.
    /// @notice Requires account's STORAGE_ROOT to be proven first with `proveAccount` function.
    function proveStorage(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        bytes32 slot,
        bytes calldata storageSlotMptProof
    ) external;

    /// @notice Verifies that block with number blockNumberLow is the latest block with timestamp less than or equal to the given timestamp.
    /// @notice Requires timestamps of block with number blockNumberLow and blockNumberLow + 1 to be proven first with `proveHeader` function.
    function proveTimestamp(uint256 chainId, uint256 timestamp, uint256 blockNumberLow) external;

    // ============ Verifying (Verifies that storage proof is correct) ============ //

    /// @notice Verifies whether block header given by headerProof is present in MMR at given chain id, which means that it is a valid block.
    /// @notice Returns array of block header fields.
    /// @notice After successful verification, it can be assumed that block header with fields returned from this function is part of the chain with given chain id.
    function verifyHeader(
        uint256 chainId,
        BlockHeaderProof calldata headerProof
    ) external view returns (bytes32[15] memory fields);

    /// @notice Verifies the accountMptProof against block's state root.
    /// @notice Returns account fields.
    /// @notice Reverts with "STORAGE_PROOF_SHOULD_BE_NON_APECHAIN" if the given chain id is ApeChain. (For ApeChain, use verifyOnlyAccountApechain instead)
    /// @notice IMPORTANT: It DOES NOT check whether state root is valid given the chain id, block number and account address.
    /// @notice To verify state root, use verifyHeader function.
    function verifyOnlyAccount(
        uint256 chainId,
        address account,
        bytes32 stateRoot,
        bytes calldata accountMptProof
    ) external pure returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot);

    /// @notice Verifies the accountMptProof and whether block given by headerProof is present in MMR at given chain id.
    /// @notice Returns account fields.
    /// @notice After successful verification, it can be assumed that account at given block number and chain id has field values returned from this function.
    function verifyAccount(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountMptProof
    ) external view returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot);

    /// @notice Verifies the accountMptProof against block's state root.
    /// @notice Returns account fields.
    /// @notice IMPORTANT: It DOES NOT check whether state root is valid given the chain id, block number and account address.
    /// @notice To verify state root, use verifyHeader function.
    /// @notice Reverts with "STORAGE_PROOF_SHOULD_BE_APECHAIN" if the given chain id is not ApeChain. (For non-ApeChain, use verifyOnlyAccount instead)
    function verifyOnlyAccountApechain(
        uint256 chainId,
        address account,
        bytes32 stateRoot,
        bytes calldata accountMptProof
    )
        external
        pure
        returns (
            uint256 nonce,
            uint256 flags,
            uint256 fixed_,
            uint256 shares,
            uint256 debt,
            uint256 delegate,
            bytes32 codeHash,
            bytes32 storageRoot
        );

    /// @notice Verifies the accountMptProof and whether block given by headerProof is present in MMR at given chain id.
    /// @notice Returns account fields.
    /// @notice After successful verification, it can be assumed that account at given block number and chain id has field values returned from this function.
    function verifyAccountApechain(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountMptProof
    )
        external
        view
        returns (
            uint256 nonce,
            uint256 flags,
            uint256 fixed_,
            uint256 shares,
            uint256 debt,
            uint256 delegate,
            bytes32 codeHash,
            bytes32 storageRoot
        );

    /// @notice Verifies the storageSlotMptProof against account's storage root.
    /// @notice Returns storage slot value.
    /// @notice IMPORTANT: It DOES NOT check whether storage root is valid given the chain id, block number, account address and slot index.
    /// @notice To verify storage root, use verifyOnlyAccount function.
    function verifyOnlyStorage(
        bytes32 slot,
        bytes32 storageRoot,
        bytes calldata storageSlotMptProof
    ) external pure returns (bytes32 slotValue);

    /// @notice Verifies the storageSlotMptProof, accountMptProof and whether block given by headerProof is present in MMR at given chain id.
    /// @notice Returns storage slot value.
    /// @notice After successful verification, it can be assumed that given slot index of the account at block number and chain id has value returned from this function.
    function verifyStorage(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        bytes32 slot,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountMptProof,
        bytes calldata storageSlotMptProof
    ) external view returns (bytes32 slotValue);

    /// @notice Verifies that block with number blockNumberLow is the latest block with timestamp less than or equal to the given timestamp.
    /// @notice IMPORTANT: It DOES NOT check if blockTimestampLow and High correspond to blockNumberLow and blockNumberLow + 1.
    /// @notice Additionally, following has to be verified:
    /// @notice - blockTimestampLow is the timestamp of block with number blockNumberLow - `headerField(chainId, blockNumberLow, BlockHeaderField.TIMESTAMP) == blockTimestampLow`
    /// @notice - blockTimestampHigh is the timestamp of block with number blockNumberLow + 1 - `headerField(chainId, blockNumberLow + 1, BlockHeaderField.TIMESTAMP) == blockTimestampHigh`
    /// @notice Both checks above can be done with `verifyHeader` (without needing to use additional storage in satellite contract).
    function verifyOnlyTimestamp(
        uint256 timestamp,
        uint256 blockNumberLow,
        uint256 blockTimestampLow,
        uint256 blockTimestampHigh
    ) external pure;

    /// @notice Verifies that block with number blockNumberLow is the latest block with timestamp less than or equal to the given timestamp and that both header proofs are present in MMR.
    /// @notice Returns block number.
    function verifyTimestamp(
        uint256 chainId,
        uint256 timestamp,
        BlockHeaderProof calldata headerProofLow,
        BlockHeaderProof calldata headerProofHigh
    ) external view returns (uint256 blockNumber);

    // ========================= Events ========================= //

    /// @notice Emitted when block header fields are proven
    event ProvenHeader(uint256 chainId, uint256 blockNumber, uint16 savedFields);

    /// @notice Emitted when account fields are proven
    event ProvenAccount(uint256 chainId, uint256 blockNumber, address account, uint8 savedFields);

    /// @notice Emitted when storage slot value is proven
    event ProvenStorage(uint256 chainId, uint256 blockNumber, address account, bytes32 slot);

    /// @notice Emitted when timestamp is proven
    event ProvenTimestamp(uint256 chainId, uint256 timestamp);
}
