// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Authenticator.t.sol";
import "../src/authenticators/EthSigAuthenticator.sol";

contract EthSigAuthenticatorTest is AuthenticatorTest, SigUtils {
    string constant name = "SnapshotX";
    string constant version = "1";

    EthSigAuthenticator public auth;

    // uint256 public constant authorKey = 1234;

    // address public constant author = vm.addr(authorKey);

    function setUp() public virtual override {
        super.setUp();
        auth = new EthSigAuthenticator();
    }

    function testAuthenticate() public {
        _generateProposeDigest(
            address(auth),
            address(target),
            address(target),
            "metadataUri",
            address(target),
            new uint256[](0),
            new bytes(0),
            0
        );
        // auth.authenticate(address(target), target.foo.selector, abi.encode(5));
        // assertEq(target.x(), 5);
    }

    function testAuthenticateRevert() public {
        // vm.expectRevert(TooBig.selector);
        // auth.authenticate(address(target), target.foo.selector, abi.encode(11));
    }
}
