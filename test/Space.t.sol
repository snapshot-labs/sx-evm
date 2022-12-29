// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Space.sol";
// import "../src/interfaces/ISpace.sol";
import "forge-std/console2.sol";
import "../src/voting-strategies/VanillaVotingStrategy.sol";

contract SpaceTest is Test {
    Space public space;

    uint32 private votingDelay = 0;
    uint32 private minVotingDuration = 0;
    uint32 private maxVotingDuration = 1000;
    uint32 private proposalThreshold = 1;
    uint32 private quorum = 1;
    address[] private votingStrategies;
    bytes[] private votingStrategiesParams;
    address[] private authenticators = [address(this)];
    address[] private executionStrategies = [address(0)];
    bytes[] private userVotingStrategyParams = [new bytes(0)];
    bytes private executionParams = new bytes(0);
    address private owner = address(this);

    uint256[] private usedVotingStrategiesIndices = [0];

    string private metadataUri = "Snapshot On-Chain";

    // TODO: add setters and test them (maybe in another test file)

    function setUp() public {
        VanillaVotingStrategy vanillaVotingStrategy = new VanillaVotingStrategy();
        votingStrategies.push(address(vanillaVotingStrategy));
        votingStrategiesParams.push(new bytes(0));

        space = new Space(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            votingStrategiesParams,
            authenticators,
            executionStrategies
        );
    }

    function testMinDurationSetUp() public {
        vm.expectRevert("Min duration should be smaller than max duration");
        new Space(
            owner,
            votingDelay,
            maxVotingDuration + 1,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            votingStrategiesParams,
            authenticators,
            executionStrategies
        );
    }

    function testEmptyVotingStrategiesSetUp() public {
        address[] memory emptyVotingStrategies = new address[](0);

        vm.expectRevert("Voting Strategies array empty");
        new Space(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            emptyVotingStrategies,
            votingStrategiesParams,
            authenticators,
            executionStrategies
        );
    }

    function testEmptyAuthenticatorsSetUp() public {
        address[] memory emptyAuthenticators = new address[](0);

        vm.expectRevert("Authenticators array empty");
        new Space(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            votingStrategiesParams,
            emptyAuthenticators,
            executionStrategies
        );
    }

    function testEmptyExecutionStrategiesSetUp() public {
        address[] memory emptyExecutionStrategies = new address[](0);

        vm.expectRevert("Execution Strategies array empty");
        new Space(
            owner,
            votingDelay,
            minVotingDuration,
            maxVotingDuration,
            proposalThreshold,
            quorum,
            votingStrategies,
            votingStrategiesParams,
            authenticators,
            emptyExecutionStrategies
        );
    }

    function testInvalidAuth() public {
        // Sender will not be a whiteslisted auth
        vm.prank(address(0));

        // Expect revert
        vm.expectRevert("Invalid Authenticator");

        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );
    }

    function testInvalidExecutionStrategy() public {
        address invalidExecutionStrategy = address(1);

        // Expect revert
        vm.expectRevert("Invalid Execution Strategy");

        space.propose(
            address(this),
            metadataUri,
            invalidExecutionStrategy,
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );
    }

    function testInvalidUsedVotingStrategy() public {
        uint256[] memory invalidUsedStrategy = new uint256[](1);
        invalidUsedStrategy[0] = 42;

        // Expect revert (out of bounds).
        vm.expectRevert();

        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            invalidUsedStrategy,
            userVotingStrategyParams,
            executionParams
        );
    }

    function testDuplicateUsedVotingStrategy() public {
        uint256[] memory invalidUsedStrategy = new uint256[](4);
        invalidUsedStrategy[0] = 0;
        invalidUsedStrategy[0] = 1;
        invalidUsedStrategy[0] = 2;
        invalidUsedStrategy[0] = 0; // Duplicate entry

        bytes[] memory _userVotingStrategyParams = new bytes[](4);
        _userVotingStrategyParams[0] = new bytes(0);
        _userVotingStrategyParams[1] = new bytes(0);
        _userVotingStrategyParams[2] = new bytes(0);
        _userVotingStrategyParams[3] = new bytes(0);

        // Expect revert
        vm.expectRevert("Duplicates found");

        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            invalidUsedStrategy,
            _userVotingStrategyParams,
            executionParams
        );
    }

    function testValidProposal() public {
        // ISpace spaceInterface = ISpace(address(space));
        // TODO: Check that the correct event gets fired
        // vm.expectEmit(true, true, true, true);
        // emit spaceInterface.ProposalCreated(address(this), address(1), 10);

        space.propose(
            address(this),
            metadataUri,
            executionStrategies[0],
            usedVotingStrategiesIndices,
            userVotingStrategyParams,
            executionParams
        );
        // TODO: get proposal Info
    }
}
