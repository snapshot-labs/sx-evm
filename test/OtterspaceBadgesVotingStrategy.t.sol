// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { OtterspaceBadgesVotingStrategy } from "../src/voting-strategies/OtterspaceBadgesVotingStrategy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Badges } from "@otterspace/contracts/Badges.sol";
import { SpecDataHolder } from "@otterspace/contracts/SpecDataHolder.sol";
import { Raft } from "@otterspace/contracts/Raft.sol";

contract UUPSProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) {}
}

contract OtterspaceBadgesVotingStrategyTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    Badges badgesImplementationV1;
    SpecDataHolder specDataHolderImplementationV1;
    Raft raftImplementationV1;

    UUPSProxy badgesUUPS;
    UUPSProxy raftUUPS;
    UUPSProxy sdhUUPS;

    Badges badgesProxy;
    Raft raftProxy;
    SpecDataHolder sdhProxy;

    uint256 passivePrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

    uint256 raftHolderPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    address passiveAddress = vm.addr(passivePrivateKey);

    uint256 claimantPrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    uint256 randomPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    address randomAddress = vm.addr(randomPrivateKey);

    address raftOwner = vm.addr(raftHolderPrivateKey);

    address claimantAddress = vm.addr(claimantPrivateKey);
    address zeroAddress = address(0);

    string[] specUris = ["spec1", "spec2"];
    string badTokenUri = "bad token uri";

    string errAirdropUnauthorized = "airdrop: unauthorized";
    string err721InvalidTokenId = "ERC721: invalid token ID";
    string errBadgeAlreadyRevoked = "revokeBadge: badge already revoked";
    string errBalanceOfNotValidOwner = "balanceOf: address(0) is not a valid owner";
    string errGiveToManyArrayMismatch = "giveToMany: recipients and signatures length mismatch";
    string errGiveRequestedBadgeToManyArrayMismatch =
        "giveRequestedBadgeToMany: recipients and signatures length mismatch";
    string errInvalidSig = "safeCheckAgreement: invalid signature";
    string errGiveRequestedBadgeInvalidSig = "giveRequestedBadge: invalid signature";
    string errOnlyBadgesContract = "onlyBadgesContract: unauthorized";
    string errNoSpecUris = "refreshMetadata: no spec uris provided";
    string errNotOwner = "Ownable: caller is not the owner";
    string errNotRaftOwner = "onlyRaftOwner: unauthorized";
    string errCreateSpecUnauthorized = "createSpec: unauthorized";
    string errNotRevoked = "reinstateBadge: badge not revoked";
    string errSafeCheckUsed = "safeCheckAgreement: already used";
    string errSpecAlreadyRegistered = "createSpec: spec already registered";
    string errSpecNotRegistered = "mint: spec is not registered";
    string errGiveUnauthorized = "give: unauthorized";
    string errUnequipSenderNotOwner = "unequip: sender must be owner";
    string errTakeUnauthorized = "take: unauthorized";
    string errMerkleInvalidLeaf = "safeCheckMerkleAgreement: invalid leaf";
    string errMerkleInvalidSignature = "safeCheckMerkleAgreement: invalid signature";
    string errTokenDoesntExist = "tokenExists: token doesn't exist";
    string errTokenExists = "mint: tokenID exists";
    string errRevokeUnauthorized = "revokeBadge: unauthorized";
    string errReinstateUnauthorized = "reinstateBadge: unauthorized";
    string errRequestedBadgeUnauthorized = "giveRequestedBadge: unauthorized";

    string specUri = "some spec uri";
    uint256 raftTokenId;

    function setUp() public {
        address contractOwner = address(this);

        badgesImplementationV1 = new Badges();
        specDataHolderImplementationV1 = new SpecDataHolder();
        raftImplementationV1 = new Raft();

        badgesUUPS = new UUPSProxy(address(badgesImplementationV1), "");
        raftUUPS = new UUPSProxy(address(raftImplementationV1), "");
        sdhUUPS = new UUPSProxy(address(specDataHolderImplementationV1), "");

        badgesProxy = Badges(address(badgesUUPS));
        raftProxy = Raft(address(raftUUPS));
        sdhProxy = SpecDataHolder(address(sdhUUPS));

        badgesProxy.initialize("Badges", "BADGES", "0.1.0", contractOwner, address(sdhUUPS));
        raftProxy.initialize(contractOwner, "Raft", "RAFT");
        sdhProxy.initialize(address(raftUUPS), contractOwner);

        sdhProxy.setBadgesAddress(address(badgesUUPS));

        vm.label(passiveAddress, "passive");
        vm.expectEmit(true, true, true, false);
        emit Transfer(zeroAddress, raftOwner, 1);
        raftTokenId = raftProxy.mint(raftOwner, specUri);

        assertEq(raftTokenId, 1);
        assertEq(raftProxy.balanceOf(raftOwner), 1);

        vm.prank(raftOwner);
        badgesProxy.createSpec(specUri, raftTokenId);
        assertEq(sdhProxy.isSpecRegistered(specUri), true);
    }

    function testOtterspaceBadgesVotingPower() public {}
}
