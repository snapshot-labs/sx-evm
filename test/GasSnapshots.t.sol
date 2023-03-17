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
    CompVotingStrategy internal compVotingStrategy;
    CompToken internal compToken;

    uint256 internal constant TOKEN_AMOUNT = 10000;

    string internal constant NAME = "snapshot-x";
    string internal constant VERSION = "1";

    EthSigAuthenticator internal ethSigAuth;
    EthTxAuthenticator internal ethTxAuth;

    uint256 internal key2;
    uint256 internal key3;
    uint256 internal key4;
    uint256 internal key5;
    uint256 internal key6;
    address internal voter2;
    address internal voter3;
    address internal voter4;
    address internal voter5;
    address internal voter6;

    // solhint-disable-next-line no-empty-blocks
    constructor() SigUtils(NAME, VERSION) {}

    function setUp() public virtual override {
        super.setUp();

        (voter2, key2) = makeAddrAndKey("Voter 2 Key");
        (voter3, key3) = makeAddrAndKey("Voter 3 Key");
        (voter4, key4) = makeAddrAndKey("Voter 4 Key");
        (voter5, key5) = makeAddrAndKey("Voter 5 Key");
        (voter6, key6) = makeAddrAndKey("Voter 6 Key");

        Strategy[] memory newVotingStrategies = new Strategy[](1);
        compVotingStrategy = new CompVotingStrategy();
        compToken = new CompToken();
        newVotingStrategies[0] = Strategy(address(compVotingStrategy), abi.encodePacked(address(compToken)));
        string[] memory newVotingStrategyMetadataURIs = new string[](0);

        // Update contract's voting strategies.
        space.addVotingStrategies(newVotingStrategies, newVotingStrategyMetadataURIs);

        uint8[] memory toRemove = new uint8[](1);
        toRemove[0] = 0;
        // Remove the vanilla voting strategy.
        space.removeVotingStrategies(toRemove);

        // Mint tokens for the users
        compToken.mint(author, TOKEN_AMOUNT);
        compToken.mint(voter, TOKEN_AMOUNT);
        compToken.mint(voter2, TOKEN_AMOUNT);
        compToken.mint(voter3, TOKEN_AMOUNT);
        compToken.mint(voter4, TOKEN_AMOUNT);
        compToken.mint(voter5, TOKEN_AMOUNT);
        compToken.mint(voter6, TOKEN_AMOUNT);
        // Delegate to self to activate checkpoints
        vm.prank(author);
        compToken.delegate(author);
        vm.prank(voter);
        compToken.delegate(voter);
        vm.prank(voter2);
        compToken.delegate(voter2);
        vm.prank(voter3);
        compToken.delegate(voter3);
        vm.prank(voter4);
        compToken.delegate(voter4);
        vm.prank(voter5);
        compToken.delegate(voter5);
        vm.prank(voter6);
        compToken.delegate(voter6);

        // Adding the eth sig authenticator to the space
        ethSigAuth = new EthSigAuthenticator(NAME, VERSION);
        ethTxAuth = new EthTxAuthenticator();
        address[] memory newAuths = new address[](2);
        newAuths[0] = address(ethSigAuth);
        newAuths[1] = address(ethTxAuth);
        space.addAuthenticators(newAuths);

        // Remove old one to make sure state is clean.
        space.removeAuthenticators(authenticators);

        // Replace with comp voting strategy which should be at index 1.
        userVotingStrategies[0] = IndexedStrategy(1, newVotingStrategies[0].params);

        Strategy[] memory currentVotingStrategies = new Strategy[](2);
        (address addy0, bytes memory params0) = space.votingStrategies(0);
        currentVotingStrategies[0] = Strategy(addy0, params0);
        (address addy1, bytes memory params1) = space.votingStrategies(1);
        currentVotingStrategies[1] = Strategy(addy1, params1);

        // Udpdate the proposal validation params
        space.setProposalValidationStrategy(
            Strategy(address(votingPowerProposalValidationContract), abi.encode(TOKEN_AMOUNT, currentVotingStrategies))
        );
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
                abi.encode(userVotingStrategies),
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
            abi.encode(author, proposalMetadataURI, executionStrategy, abi.encode(userVotingStrategies))
        );

        (v, r, s) = vm.sign(
            AUTHOR_KEY,
            _getProposeDigest(
                address(ethSigAuth),
                address(space),
                address(author),
                proposalMetadataURI,
                executionStrategy,
                abi.encode(userVotingStrategies),
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
            abi.encode(author, proposalMetadataURI, executionStrategy, abi.encode(userVotingStrategies))
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
            key2,
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
            key3,
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
