// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { OracleVotingStrategy } from "../src/voting-strategies/OracleVotingStrategy.sol";

contract OracleVotingStrategyTest is Test {
    OracleVotingStrategy public oracleVotingStrategy;

    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 private constant SCORE_TYPEHASH =
        keccak256("Score(bytes params,uint256 votingPower,uint32 timestamp,address voter)");

    error InvalidSignature();
    error InvalidTimestamp();
    error InvalidVoter();

    // Fictional Oracle Private Key
    uint256 public constant ORACLE_KEY = 1234;
    // Oracle address based on the fiction private key
    address public ORACLE_ADDRESS = vm.addr(ORACLE_KEY);

    // Voter address
    address constant VOTER = address(1337);

    string constant NAME = "Oracle Voting Strategy";
    string constant VERSION = "1";

    function setUp() public {
        oracleVotingStrategy = new OracleVotingStrategy(NAME, VERSION);
    }

    // Returns the EIP712 digest
    function _getDigest(
        address oracleVotingStrategy_,
        bytes memory params_,
        uint256 votingPower,
        uint32 timestamp,
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
                keccak256(abi.encode(SCORE_TYPEHASH, keccak256(params_), votingPower, timestamp, voter_))
            )
        );

        return digest;
    }

    function testGetVotingPower() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 timestamp = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, timestamp, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(timestamp, VOTER, votingPower, r, s, v);

        // The voting power should be correctly returned
        assertEq(oracleVotingStrategy.getVotingPower(timestamp, VOTER, params, userParams), votingPower);
    }

    function testGetVotingPowerInvalidOracle() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 timestamp = 1111;

        address randomAddress = address(2222);
        // Get the digest
        bytes32 digest = _getDigest(randomAddress, params_, votingPower, timestamp, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(timestamp, VOTER, votingPower, r, s, v);

        // Since the oracle address is incorrect, the voting strategy should revert
        vm.expectRevert(InvalidSignature.selector);
        oracleVotingStrategy.getVotingPower(timestamp, VOTER, params, userParams);
    }

    function testGetVotingPowerInvalidParams() public {
        // Empty strategy parameters
        bytes memory params_ = "";

        uint256 votingPower = 4242;
        uint32 timestamp = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, timestamp, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(timestamp, VOTER, votingPower, r, s, v);

        // Since the params is incorrect, the voting strategy should revert
        vm.expectRevert(InvalidSignature.selector);
        bytes memory modifiedParams_ = "0x1";
        bytes memory modifiedParams = abi.encode(ORACLE_ADDRESS, modifiedParams_);
        oracleVotingStrategy.getVotingPower(timestamp, VOTER, modifiedParams, userParams);
    }

    function testGetVotingPowerInvalidVP() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 timestamp = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, timestamp, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        // Since the params is incorrect, the voting strategy should revert
        vm.expectRevert(InvalidSignature.selector);
        uint256 modifiedVP = 1;
        bytes memory userParams = abi.encode(timestamp, VOTER, modifiedVP, r, s, v);
        oracleVotingStrategy.getVotingPower(timestamp, VOTER, params, userParams);
    }

    function testGetVotingPowerInvalidTimestamp() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 timestamp = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, timestamp, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(timestamp, VOTER, votingPower, r, s, v);

        // The voting power should be correctly returned
        vm.expectRevert(InvalidTimestamp.selector);
        uint32 modifiedTimestamp = 2222;
        oracleVotingStrategy.getVotingPower(modifiedTimestamp, VOTER, params, userParams);
    }

    function testGetVotingPowerInvalidVoter() public {
        // Empty strategy parameters
        bytes memory params_ = "";
        bytes memory params = abi.encode(ORACLE_ADDRESS, params_);

        uint256 votingPower = 4242;
        uint32 timestamp = 1111;

        // Get the digest
        bytes32 digest = _getDigest(address(oracleVotingStrategy), params_, votingPower, timestamp, VOTER);
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, digest);

        bytes memory userParams = abi.encode(timestamp, VOTER, votingPower, r, s, v);

        // The voting power should be correctly returned
        vm.expectRevert(InvalidVoter.selector);
        address modifiedVoter = address(8888);
        oracleVotingStrategy.getVotingPower(timestamp, modifiedVoter, params, userParams);
    }
}
