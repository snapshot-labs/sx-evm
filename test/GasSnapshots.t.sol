// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { CompVotingStrategy } from "../src/voting-strategies/CompVotingStrategy.sol";
import { CompToken } from "./mocks/CompToken.sol";
import { SpaceTest } from "./utils/Space.t.sol";
import { SigUtils } from "./utils/SigUtils.sol";
import { EthSigAuthenticator } from "../src/authenticators/EthSigAuthenticator.sol";
import { EthTxAuthenticator } from "../src/authenticators/EthTxAuthenticator.sol";
import { Choice, IndexedStrategy, Strategy } from "../src/types.sol";

contract GasSnapshotsTest is SpaceTest, SigUtils {
    CompVotingStrategy public compVotingStrategy;
    CompToken public compToken;

    string private constant NAME = "snapshot-x";
    string private constant VERSION = "1";

    EthSigAuthenticator public ethSigAuth;
    EthTxAuthenticator public ethTxAuth;

    uint256 VOTER2_KEY;
    uint256 VOTER3_KEY;
    uint256 VOTER4_KEY;
    uint256 VOTER5_KEY;
    uint256 VOTER6_KEY;
    address voter2;
    address voter3;
    address voter4;
    address voter5;
    address voter6;

    // solhint-disable-next-line no-empty-blocks
    constructor() SigUtils(NAME, VERSION) {}

    function setUp() public virtual override {
        super.setUp();

        (voter2, VOTER2_KEY) = makeAddrAndKey("Voter 2 Key");
        (voter3, VOTER3_KEY) = makeAddrAndKey("Voter 3 Key");
        (voter4, VOTER4_KEY) = makeAddrAndKey("Voter 4 Key");
        (voter5, VOTER5_KEY) = makeAddrAndKey("Voter 5 Key");
        (voter6, VOTER6_KEY) = makeAddrAndKey("Voter 6 Key");

        Strategy[] memory newVotingStrategies = new Strategy[](1);
        compVotingStrategy = new CompVotingStrategy();
        compToken = new CompToken();
        newVotingStrategies[0] = Strategy(address(compVotingStrategy), abi.encodePacked(address(compToken)));
        string[] memory newVotingStrategyMetadataURIs = new string[](0);

        // Update contract's voting strategies.
        space.addVotingStrategies(newVotingStrategies, newVotingStrategyMetadataURIs);

        // Mint tokens for the users
        compToken.mint(author, 10000);
        compToken.mint(voter, 10000);
        compToken.mint(voter2, 10000);
        compToken.mint(voter3, 10000);
        // Delegate to self to activate checkpoints
        vm.prank(author);
        compToken.delegate(author);
        vm.prank(voter);
        compToken.delegate(voter);
        vm.prank(voter2);
        compToken.delegate(voter2);
        vm.prank(voter3);
        compToken.delegate(voter3);

        // Adding the eth sig authenticator to the space
        ethSigAuth = new EthSigAuthenticator(NAME, VERSION);
        ethTxAuth = new EthTxAuthenticator();
        address[] memory newAuths = new address[](2);
        newAuths[0] = address(ethSigAuth);
        newAuths[1] = address(ethTxAuth);
        space.addAuthenticators(newAuths);

        // Remove old one to make sure state is clean.
        space.removeAuthenticators(authenticators);

        // Delete strategy [0] because it's the vanilla one.
        delete userVotingStrategies[0];
        // Add the new comp voting strategy which should be at index 1.
        userVotingStrategies.push(IndexedStrategy(1, new bytes(0)));
    }

    function testVoteAndProposeWithCompToken() public {
        vm.roll(block.number + 1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            AUTHOR_KEY,
            _getProposeDigest(
                address(ethSigAuth),
                address(space),
                address(author),
                proposalMetadataURI,
                executionStrategy,
                userVotingStrategies,
                0
            )
        );

        ethSigAuth.authenticate(
            v,
            r,
            s,
            0,
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(author, proposalMetadataURI, executionStrategy, userVotingStrategies)
        );

        (v, r, s) = vm.sign(
            AUTHOR_KEY,
            _getProposeDigest(
                address(ethSigAuth),
                address(space),
                address(author),
                proposalMetadataURI,
                executionStrategy,
                userVotingStrategies,
                1
            )
        );
        // We take the snapshot on the second proposal because the first proposal will write to new
        // storage making it not representative of average usage.
        snapStart("ProposeSigComp");
        ethSigAuth.authenticate(
            v,
            r,
            s,
            1,
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(author, proposalMetadataURI, executionStrategy, userVotingStrategies)
        );
        snapEnd();

        uint256 proposalId = 1;

        (v, r, s) = vm.sign(
            VOTER_KEY,
            _getVoteDigest(address(ethSigAuth), address(space), voter, proposalId, Choice.For, userVotingStrategies, "")
        );
        ethSigAuth.authenticate(
            v,
            r,
            s,
            0,
            address(space),
            VOTE_SELECTOR,
            abi.encode(voter, proposalId, Choice.For, userVotingStrategies, "")
        );

        (v, r, s) = vm.sign(
            VOTER2_KEY,
            _getVoteDigest(
                address(ethSigAuth),
                address(space),
                voter2,
                proposalId,
                Choice.For,
                userVotingStrategies,
                ""
            )
        );

        // We take the snapshot on the second vote because the first vote will write to new
        // storage making it not representative of average usage.
        snapStart("VoteSigComp");
        ethSigAuth.authenticate(
            v,
            r,
            s,
            0,
            address(space),
            VOTE_SELECTOR,
            abi.encode(voter2, proposalId, Choice.For, userVotingStrategies, "")
        );
        snapEnd();

        (v, r, s) = vm.sign(
            VOTER3_KEY,
            _getVoteDigest(
                address(ethSigAuth),
                address(space),
                voter3,
                proposalId,
                Choice.For,
                userVotingStrategies,
                "bafkreibv2yjocyotgj2n6awe5z7vqxrzyo72t2ml2ijgj4fgktfpyukuv4"
            )
        );

        // Adding metadata with the vote
        snapStart("VoteSigCompMetadata");
        ethSigAuth.authenticate(
            v,
            r,
            s,
            0,
            address(space),
            VOTE_SELECTOR,
            abi.encode(
                voter3,
                proposalId,
                Choice.For,
                userVotingStrategies,
                "bafkreibv2yjocyotgj2n6awe5z7vqxrzyo72t2ml2ijgj4fgktfpyukuv4"
            )
        );
        snapEnd();

        vm.prank(voter4);
        ethTxAuth.authenticate(
            address(space),
            VOTE_SELECTOR,
            abi.encode(voter4, proposalId, Choice.For, userVotingStrategies, "")
        );

        vm.prank(voter5);
        snapStart("VoteTxComp");
        ethTxAuth.authenticate(
            address(space),
            VOTE_SELECTOR,
            abi.encode(voter5, proposalId, Choice.For, userVotingStrategies, "")
        );
        snapEnd();

        vm.prank(voter6);
        snapStart("VoteTxCompMetadata");
        ethTxAuth.authenticate(
            address(space),
            VOTE_SELECTOR,
            abi.encode(
                voter6,
                proposalId,
                Choice.For,
                userVotingStrategies,
                "bafkreibv2yjocyotgj2n6awe5z7vqxrzyo72t2ml2ijgj4fgktfpyukuv4"
            )
        );
        snapEnd();
    }
}
