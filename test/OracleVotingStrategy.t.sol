// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { OracleVotingStrategy } from "../src/voting-strategies/OracleVotingStrategy.sol";

// Minimal EIP-1271 wallet mimicking a 2-of-2 Safe
// The signature is the concatenation of two 65-byte ECDSA signatures, one per owner
// Note: illustrative only. A real Safe wraps the digest in a SafeMessage under its own domain
// separator, requires owner signatures sorted by ascending owner address, and reverts on failure.
contract MockSafe {
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    address public immutable owner1;
    address public immutable owner2;

    constructor(address _owner1, address _owner2) {
        owner1 = _owner1;
        owner2 = _owner2;
    }

    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4) {
        if (signature.length != 130) return 0xffffffff;

        (bytes32 r1, bytes32 s1, uint8 v1) = _split(signature, 0);
        (bytes32 r2, bytes32 s2, uint8 v2) = _split(signature, 65);

        if (ecrecover(hash, v1, r1, s1) != owner1) return 0xffffffff;
        if (ecrecover(hash, v2, r2, s2) != owner2) return 0xffffffff;

        return MAGICVALUE;
    }

    function _split(bytes memory sig, uint256 offset) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(sig, add(0x20, offset)))
            s := mload(add(sig, add(0x40, offset)))
            v := byte(0, mload(add(sig, add(0x60, offset))))
        }
    }
}

// EIP-1271 wallet that accepts any signature, including an empty one
contract MockAcceptAllWallet {
    function isValidSignature(bytes32, bytes memory) external pure returns (bytes4) {
        return 0x1626ba7e;
    }
}

// EIP-1271 wallet that always reverts
contract MockRevertingWallet {
    function isValidSignature(bytes32, bytes memory) external pure returns (bytes4) {
        revert("no");
    }
}

// EIP-1271 wallet that returns a wrong magic value
contract MockWrongMagicWallet {
    function isValidSignature(bytes32, bytes memory) external pure returns (bytes4) {
        return 0xdeadbeef;
    }
}

contract OracleVotingStrategyTest is Test {
    OracleVotingStrategy public oracleVotingStrategy;

    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 private constant SCORE_TYPEHASH =
        keccak256("Score(bytes params,uint256 votingPower,uint32 blockNumber,address voter)");

    error InvalidSignature();

    // Fictional Oracle Private Key
    uint256 public constant ORACLE_KEY = 1234;
    // Second fictional private key, used as co-owner of the EIP-1271 wallet
    uint256 public constant ORACLE_KEY_2 = 5678;
    // Oracle address based on the fictional private key
    address public ORACLE_ADDRESS = vm.addr(ORACLE_KEY);

    // Voter address
    address constant VOTER = address(1337);

    string constant NAME = "snapshot-x";
    string constant VERSION = "1.0.0";

    function setUp() public {
        oracleVotingStrategy = new OracleVotingStrategy(NAME, VERSION);
    }

    // Returns the EIP712 digest
    function _getDigest(
        address oracleVotingStrategy_,
        bytes memory params_,
        uint256 votingPower,
        uint32 blockNumber,
        address voter_
    ) internal view returns (bytes32) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                keccak256(
                    abi.encode(
                        DOMAIN_TYPEHASH,
                        keccak256(bytes(NAME)),
                        keccak256(bytes(VERSION)),
                        block.chainid,
                        oracleVotingStrategy_
                    )
                ),
                keccak256(abi.encode(SCORE_TYPEHASH, keccak256(params_), votingPower, blockNumber, voter_))
            )
        );

        return digest;
    }

    // Pins the typehash so an accidental edit of the struct string gets caught
    function testScoreTypehash() public {
        assertEq(SCORE_TYPEHASH, 0x8bbacba2eb4f68650078790dfdd551f66553a615b15aacd9613277148a0252ef);
    }

    function testGetVotingPower() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(r, s, v));

        // The voting power should be correctly returned
        assertEq(oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams), votingPower);
    }

    function testGetVotingPowerNonEmptyParams() public {
        // Non-empty strategy parameters
        bytes memory params_ = abi.encode(uint256(123), "some strategy config");
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(r, s, v));

        // The voting power should be correctly returned
        assertEq(oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams), votingPower);
    }

    function testGetVotingPowerInvalidOracle() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        // The strategy params designate an oracle that is not the actual signer
        bytes memory params = abi.encode(address(2222), params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(r, s, v));

        // Since the signature does not come from the designated oracle, the voting strategy should revert
        vm.expectRevert(InvalidSignature.selector);
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams);
    }

    function testGetVotingPowerInvalidVerifyingContract() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        address randomAddress = address(2222);
        // Get the digest, using a verifying contract that is not the strategy
        bytes32 digest = _getDigest(randomAddress, params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(r, s, v));

        // Since the signature is bound to another verifying contract, the voting strategy should revert
        vm.expectRevert(InvalidSignature.selector);
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams);
    }

    function testGetVotingPowerInvalidParams() public {
        // Empty strategy parameters
        bytes memory params_ = "";

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(r, s, v));

        // Since the params is incorrect, the voting strategy should revert
        vm.expectRevert(InvalidSignature.selector);
        bytes memory modifiedParams_ = "0x1";
        bytes memory modifiedParams = abi.encode(ORACLE_ADDRESS, modifiedParams_);
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, modifiedParams, userParams);
    }

    function testGetVotingPowerInvalidVP() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        // Since the voting power is incorrect, the voting strategy should revert
        vm.expectRevert(InvalidSignature.selector);
        uint256 modifiedVP = 1;
        bytes memory userParams = abi.encode(modifiedVP, abi.encodePacked(r, s, v));
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams);
    }

    function testGetVotingPowerInvalidBlockNumber() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(r, s, v));

        // Since the block number is incorrect, the voting strategy should revert
        vm.expectRevert(InvalidSignature.selector);
        uint32 modifiedBlockNumber = 2222;
        oracleVotingStrategy.getVotingPower(modifiedBlockNumber, VOTER, params, userParams);
    }

    function testGetVotingPowerInvalidVoter() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(r, s, v));

        // Invalid voter should revert
        vm.expectRevert(InvalidSignature.selector);
        address modifiedVoter = address(8888);
        oracleVotingStrategy.getVotingPower(blockNumber, modifiedVoter, params, userParams);
    }

    function testGetVotingPowerEmptySignature() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        bytes memory userParams = abi.encode(votingPower, bytes(""));

        // An empty signature is not a valid ECDSA signature and should revert
        vm.expectRevert(InvalidSignature.selector);
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams);
    }

    function testGetVotingPowerEIP1271EmptySignature() public {
        // Use a wallet that accepts any signature as the oracle
        MockAcceptAllWallet wallet = new MockAcceptAllWallet();

        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(address(wallet), params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        bytes memory userParams = abi.encode(votingPower, bytes(""));

        // An empty signature accepted by an EIP-1271 wallet is valid,
        // e.g. Safe's pre-approved message hashes
        assertEq(oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams), votingPower);
    }

    function testGetVotingPowerCompactSignature() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        // Re-encode the valid signature as a 64-byte EIP-2098 compact signature
        bytes32 vs = bytes32(uint256(s) | (uint256(v - 27) << 255));
        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(r, vs));

        // 64-byte compact signatures are not supported and should revert
        vm.expectRevert(InvalidSignature.selector);
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams);
    }

    function testGetVotingPowerInvalidSignatureLength() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        // Append a garbage byte to the valid signature, resulting in 66 bytes
        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(r, s, v, uint8(0)));

        // Signatures of unexpected length should revert
        vm.expectRevert(InvalidSignature.selector);
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams);
    }

    function testGetVotingPowerRevertingWallet() public {
        // Use a wallet that always reverts as the oracle
        MockRevertingWallet wallet = new MockRevertingWallet();

        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(address(wallet), params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(bytes32(0), bytes32(0), uint8(0)));

        // A reverting EIP-1271 wallet should make the voting strategy revert
        vm.expectRevert(InvalidSignature.selector);
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams);
    }

    function testGetVotingPowerWrongMagicWallet() public {
        // Use a wallet that returns a wrong magic value as the oracle
        MockWrongMagicWallet wallet = new MockWrongMagicWallet();

        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(address(wallet), params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        bytes memory userParams = abi.encode(votingPower, abi.encodePacked(bytes32(0), bytes32(0), uint8(0)));

        // A wallet returning a wrong magic value should make the voting strategy revert
        vm.expectRevert(InvalidSignature.selector);
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams);
    }

    function testGetVotingPowerEIP1271() public {
        // Deploy a 2-of-2 Safe-like wallet as the oracle
        MockSafe safe = new MockSafe(vm.addr(ORACLE_KEY), vm.addr(ORACLE_KEY_2));

        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(address(safe), params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest with both owners, resulting in a 130 bytes signature
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(ORACLE_KEY, digest);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(ORACLE_KEY_2, digest);
        bytes memory signature = abi.encodePacked(r1, s1, v1, r2, s2, v2);

        bytes memory userParams = abi.encode(votingPower, signature);

        // The voting power should be correctly returned
        assertEq(oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams), votingPower);
    }

    function testGetVotingPowerEIP1271InvalidSigner() public {
        // Deploy a 2-of-2 Safe-like wallet as the oracle
        MockSafe safe = new MockSafe(vm.addr(ORACLE_KEY), vm.addr(ORACLE_KEY_2));

        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(address(safe), params_);

        uint256 votingPower = 4242;
        uint32 blockNumber = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, blockNumber, VOTER);
        // Sign the digest with the first owner and a key that is not an owner of the wallet
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(ORACLE_KEY, digest);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(9999, digest);
        bytes memory signature = abi.encodePacked(r1, s1, v1, r2, s2, v2);

        bytes memory userParams = abi.encode(votingPower, signature);

        // Since one of the two owners did not sign, the voting strategy should revert
        vm.expectRevert(InvalidSignature.selector);
        oracleVotingStrategy.getVotingPower(blockNumber, VOTER, params, userParams);
    }
}
