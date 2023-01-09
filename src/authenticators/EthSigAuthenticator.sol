// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Authenticator.sol";
import "./SignatureVerifier.sol";

contract EthSigAuthenticator is Authenticator, SignatureVerifier {
    error InvalidFunctionSelector();

    bytes4 private constant PROPOSE_SELECTOR =
        bytes4(keccak256("propose(address,string,address,uint256[],bytes[],bytes)"));

    function authenticate(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 salt,
        address target,
        bytes4 functionSelector,
        bytes memory data
    ) external {
        if (functionSelector == PROPOSE_SELECTOR) {
            _verifyProposeSig(v, r, s, salt, target, data);
        } else {
            revert InvalidFunctionSelector();
        }
        _call(target, functionSelector, data);
    }
}
