// SPDX-License-Identifier: UNLICENSED

// TODO: Replace deployment with space factory once we have it

pragma solidity ^0.8.15;

// import "forge-std/Test.sol";
// import "forge-std/console2.sol";
// import "../src/Space.sol";
// import "../src/types.sol";
// import "../src/voting-strategies/VanillaVotingStrategy.sol";
// import "../src/interfaces/space/ISpaceEvents.sol";
// import { GasSnapshot } from "forge-gas-snapshot/GasSnapshot.sol";

contract SpaceDeploymentTest {
    // function testMinDurationSetUp() public {
    //     vm.expectRevert("Min duration should be smaller than or equal to max duration");
    //     new Space(
    //         owner,
    //         votingDelay,
    //         maxVotingDuration + 1,
    //         maxVotingDuration,
    //         proposalThreshold,
    //         quorum,
    //         votingStrategies,
    //         authenticators,
    //         executionStrategies
    //     );
    // }
    // function testEmptyVotingStrategiesSetUp() public {
    //     VotingStrategy[] memory emptyVotingStrategies = new VotingStrategy[](0);
    //     vm.expectRevert("Voting Strategies array empty");
    //     new Space(
    //         owner,
    //         votingDelay,
    //         minVotingDuration,
    //         maxVotingDuration,
    //         proposalThreshold,
    //         quorum,
    //         emptyVotingStrategies,
    //         authenticators,
    //         executionStrategies
    //     );
    // }
    // function testEmptyAuthenticatorsSetUp() public {
    //     address[] memory emptyAuthenticators = new address[](0);
    //     vm.expectRevert("Authenticators array empty");
    //     new Space(
    //         owner,
    //         votingDelay,
    //         minVotingDuration,
    //         maxVotingDuration,
    //         proposalThreshold,
    //         quorum,
    //         votingStrategies,
    //         emptyAuthenticators,
    //         executionStrategies
    //     );
    // }
    // function testEmptyExecutionStrategiesSetUp() public {
    //     address[] memory emptyExecutionStrategies = new address[](0);
    //     vm.expectRevert("Execution Strategies array empty");
    //     new Space(
    //         owner,
    //         votingDelay,
    //         minVotingDuration,
    //         maxVotingDuration,
    //         proposalThreshold,
    //         quorum,
    //         votingStrategies,
    //         authenticators,
    //         emptyExecutionStrategies
    //     );
    // }
}
