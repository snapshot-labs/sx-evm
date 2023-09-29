// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// import { Badges } from "@otterspace/contracts/Badges.sol";
import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";

interface IBadges {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title Otterspace Badge Voting Strategy
/// @notice Allows Otterspace Badges to be used for voting power.
contract OtterspaceBadgesVotingStrategy is IVotingStrategy {
    error InvalidBadge();

    /// @notice The address of the Otterspace Badges Contract.
    address public badgesRegistry;

    /// @dev Data stored as parameters for each Badge.
    struct Badge {
        // spec of the badge.
        string specUri;
        // The voting power granted to badges of this spec.
        uint96 vp;
    }

    constructor(address BadgesRegistry) {
        badgesRegistry = BadgesRegistry;
    }

    /// @notice Returns the voting power of an address.
    /// @param voter The address to get the voting power of.
    /// @param params Parameter array containing an array of Badge structs.
    /// @param userParams Parameter array containing an array of indices of the badges the voter owns.
    /// @return votingPower The voting power of the address if it exists in the whitelist, otherwise reverts.
    function getVotingPower(
        uint32 /* blockNumber */,
        address voter,
        bytes calldata params,
        bytes calldata userParams
    ) external view override returns (uint256 votingPower) {
        Badge[] memory badges = abi.decode(params, (Badge[]));
        uint8[] memory userBadgeIndices = abi.decode(userParams, (uint8[]));

        uint256 vp;
        for (uint8 i = 0; i < userBadgeIndices.length; i++) {
            uint256 tokenId = uint256(getBadgeIdHash(voter, badges[userBadgeIndices[i]].specUri));
            if (IBadges(badgesRegistry).ownerOf(tokenId) != voter) revert InvalidBadge();
            vp += badges[userBadgeIndices[i]].vp;
        }

        return vp;
    }

    /// @dev Generates the unique ID of a badge for a given address and spec.
    function getBadgeIdHash(address _to, string memory _uri) internal pure returns (bytes32) {
        return keccak256(abi.encode(_to, _uri));
    }
}
