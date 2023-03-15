// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { CompVotingStrategy } from "../src/voting-strategies/CompVotingStrategy.sol";
import { CompToken } from "./mocks/CompToken.sol";
import { SpaceTest } from "./utils/Space.t.sol";
import { SigUtils } from "./utils/SigUtils.sol";
import { EthSigAuthenticator } from "../src/authenticators/EthSigAuthenticator.sol";
import { Choice, IndexedStrategy, Strategy } from "../src/types.sol";

contract GasSnapshotsTest is SpaceTest, SigUtils {
    CompVotingStrategy public compVotingStrategy;
    CompToken public compToken;

    EthSigAuthenticator public ethSigAuth;

    string private constant NAME = "snapshot-x";
    string private constant VERSION = "1";

    address public user = address(this);

    // solhint-disable-next-line no-empty-blocks
    constructor() SigUtils(NAME, VERSION) {}

    function setUp() public virtual override {
        super.setUp();

        Strategy[] memory newStrategies = new Strategy[](1);
        compVotingStrategy = new CompVotingStrategy();
        compToken = new CompToken();
        newStrategies[0] = Strategy(address(compVotingStrategy), abi.encodePacked(address(compToken)));
        bytes[] memory newData = new bytes[](0);

        // Update contract's voting strategies.
        space.addVotingStrategies(newStrategies, newData);

        uint8[] memory toRemove = new uint8[](1);
        toRemove[0] = 0;
        // Remove the vanilla voting strategy.
        space.removeVotingStrategies(toRemove);

        // Mint tokens for the author
        compToken.mint(user, 10000);
        // Must delegate to self to activate checkpoints
        compToken.delegate(author);

        // Adding the eth sig authenticator to the space
        ethSigAuth = new EthSigAuthenticator(NAME, VERSION);
        address[] memory newAuths = new address[](1);
        newAuths[0] = address(ethSigAuth);
        space.addAuthenticators(newAuths);

        // Remove old one to make sure state is clean.
        space.removeAuthenticators(authenticators);

        // Delete strategy [0] because it's the vanilla one.
        userVotingStrategies[0] = IndexedStrategy(1, newStrategies[0].params);
        // Add the new comp voting strategy which should be at index 1.
        // userVotingStrategies.push(IndexedStrategy(1, new bytes(0)));

        Strategy[] memory currentVotingStrategies = new Strategy[](2);
        (address addy0, bytes memory params0) = space.votingStrategies(0);
        currentVotingStrategies[0] = Strategy(addy0, params0);
        (address addy1, bytes memory params1) = space.votingStrategies(1);
        currentVotingStrategies[1] = Strategy(addy1, params1);

        // Udpdate the proposal validation params
        space.setProposalValidationStrategy(
            Strategy(address(votingPowerProposalValidationContract), abi.encode(10000, currentVotingStrategies))
        );
    }

    function testSnapshots() public {
        // Propose
        {
            // Advance one block or the block will be considered invalid.
            vm.roll(block.number + 1);

            uint256 salt = 0;
            bytes32 digest = _getProposeDigest(
                address(ethSigAuth),
                address(space),
                address(author),
                proposalMetadataUri,
                executionStrategy,
                abi.encode(userVotingStrategies),
                salt
            );
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(AUTHOR_KEY, digest);

            snapStart("ProposeSigComp");
            ethSigAuth.authenticate(
                v,
                r,
                s,
                salt,
                address(space),
                PROPOSE_SELECTOR,
                abi.encode(author, proposalMetadataUri, executionStrategy, abi.encode(userVotingStrategies))
            );
            snapEnd();
        }

        // Vote
        {
            uint256 proposalId = 1;
            bytes32 digest = _getVoteDigest(
                address(ethSigAuth),
                address(space),
                author,
                proposalId,
                Choice.For,
                userVotingStrategies,
                voteMetadataUri
            );
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(AUTHOR_KEY, digest);

            snapStart("VoteSigComp");
            ethSigAuth.authenticate(
                v,
                r,
                s,
                0,
                address(space),
                VOTE_SELECTOR,
                abi.encode(author, proposalId, Choice.For, userVotingStrategies, voteMetadataUri)
            );
            snapEnd();
        }
    }
}
