// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./utils/Space.t.sol";
import "./utils/Authenticator.t.sol";
import "./utils/SigUtils.sol";
import "../src/authenticators/EthSigAuthenticator.sol";

import "forge-std/console2.sol";

contract EthSigAuthenticatorTest is SpaceTest, SigUtils {
    string private constant name = "SOC";
    string private constant version = "1";

    EthSigAuthenticator public ethSigAuth;

    constructor() SigUtils(name, version) {}

    function setUp() public virtual override {
        super.setUp();

        // Adding the eth sig authenticator to the space
        ethSigAuth = new EthSigAuthenticator(name, version);
        address[] memory newAuths = new address[](1);
        newAuths[0] = address(ethSigAuth);
        space.addAuthenticators(newAuths);
    }

    function testAuthenticate() public {
        uint256 salt = 0;
        bytes32 digest = _getProposeDigest(
            address(ethSigAuth),
            address(space),
            address(author),
            proposalMetadataUri,
            executionStrategy,
            userVotingStrategies,
            salt
        );
        console2.logBytes32(digest);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(authorKey, digest);

        ethSigAuth.authenticate(
            v,
            r,
            s,
            salt,
            address(space),
            PROPOSE_SELECTOR,
            abi.encode(author, proposalMetadataUri, executionStrategy, userVotingStrategies)
        );
        // auth.authenticate(address(target), target.foo.selector, abi.encode(5));
        // assertEq(target.x(), 5);
    }

    function testAuthenticateRevert() public {
        // vm.expectRevert(TooBig.selector);
        // auth.authenticate(address(target), target.foo.selector, abi.encode(11));
    }
}
