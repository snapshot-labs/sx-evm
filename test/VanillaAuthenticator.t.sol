// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { AuthenticatorTest } from "./utils/Authenticator.t.sol";
import { VanillaAuthenticator } from "../src/authenticators/VanillaAuthenticator.sol";

contract VanillaAuthenticatorTest is AuthenticatorTest {
    VanillaAuthenticator public auth;

    function setUp() public virtual override {
        super.setUp();
        auth = new VanillaAuthenticator();
    }

    function testAuthenticate() public {
        auth.authenticate(address(target), target.foo.selector, abi.encode(5));
        assertEq(target.x(), 5);
    }

    function testAuthenticateRevert() public {
        vm.expectRevert(TooBig.selector);
        auth.authenticate(address(target), target.foo.selector, abi.encode(11));
    }
}
