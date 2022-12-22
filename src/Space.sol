// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/console2.sol";
import "src/interfaces/IVotingStrategy.sol";

// TODO: Ownable? Eip712?
contract Space {
    // notice: `uint32::max` corresponds to year ~2106.
    struct Proposal {
        uint256 quorum;
        uint32 snapshotTimestamp;
        uint32 startTimestamp;
        uint32 minEndTimestamp;
        uint32 maxEndTimestamp;
        address executionStrategy;
        bytes32 executionHash;
    }

    event ProposalCreated(
        uint256 proposalId,
        address proposerAddress,
        Proposal proposal,
        string metadataUri,
        bytes executionParams
    );

    uint32 private votingDelay;
    uint32 private minVotingDuration;
    uint32 private maxVotingDuration;

    uint256 private proposalThreshold;
    uint256 private quorum;
    mapping(address => bool) private executionStrategies;
    mapping(address => bool) private authenticators;
    mapping(address => bool) private votingStrategies;
    mapping(address => bytes) private votingStrategiesParams;
    uint256 private nextProposalNonce;
    mapping(uint256 => Proposal) private proposalRegistry;
    mapping(uint256 => bool) private executedProposals;

    constructor(
        uint32 _votingDelay,
        uint32 _minVotingDuration,
        uint32 _maxVotingDuration,
        uint256 _proposalThreshold,
        uint256 _quorum,
        address[] memory _votingStrategies,
        bytes[] memory _votingStrategiesParams,
        address[] memory _authenticators,
        address[] memory _executionStrategies
    ) {
        require(_minVotingDuration <= _maxVotingDuration, "Min duration should be smaller than max duration");
        require(_votingStrategies.length > 0, "Voting Strategies array empty");
        require(_authenticators.length > 0, "Authenticators array empty");
        require(_executionStrategies.length > 0, "Execution Strategies array empty");
        require(
            _votingStrategies.length == _votingStrategiesParams.length,
            "Strategies and Strategies Parameters length mismatch"
        );

        votingDelay = _votingDelay;
        minVotingDuration = _minVotingDuration;
        maxVotingDuration = _maxVotingDuration;
        proposalThreshold = _proposalThreshold;
        quorum = _quorum;

        for (uint i = 0; i < _votingStrategies.length; i++) {
            address strategy = _votingStrategies[i];
            votingStrategies[strategy] = true;
            votingStrategiesParams[strategy] = _votingStrategiesParams[i];
        }

        for (uint i = 0; i < _executionStrategies.length; i++) {
            executionStrategies[_executionStrategies[i]] = true;
        }
        for (uint i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = true;
        }

        nextProposalNonce = 1;
    }

    function _assertValidAuthenticator() private view {
        require(authenticators[msg.sender], "Invalid Authenticator");
    }

    function _assertValidExecutionStrategy(address executionStrategy) private view {
        require(executionStrategies[executionStrategy], "Invalid Execution Strategy");
    }

    // No way to declare a mapping in memory so we need to use an array and go for O(n^2)...
    function _assertNoDuplicates(address[] memory arr) private pure {
        if (arr.length > 0) {
            for (uint i = 0; i < arr.length - 1; i++) {
                for (uint j = i + 1; j < arr.length; j++) {
                    require(arr[i] != arr[j], "Duplicates found"); // TODO: should we use a `if` to reduce gas cost?
                }
            }
        }
    }

    function _getCumulativeVotingPower(
        uint32 timestamp,
        address userAddress,
        address[] memory usedVotingStrategies,
        bytes[] memory userVotingStrategyParams
    ) private view returns (uint256) {
        // Make sure there are no duplicates to avoid an attack where people double count a voting strategy
        _assertNoDuplicates(usedVotingStrategies);

        uint256 totalVotingPower = 0;
        for (uint i = 0; i < usedVotingStrategies.length; i++) {
            address strategyAddress = usedVotingStrategies[i];
            bool strategyExists = votingStrategies[strategyAddress];
            require(strategyExists, "Invalid used strategy");
            IVotingStrategy strategy = IVotingStrategy(strategyAddress);
            totalVotingPower += strategy.getVotingPower(
                timestamp,
                userAddress,
                votingStrategiesParams[strategyAddress],
                userVotingStrategyParams[i]
            );
            // TODO: use SafeMath, check overflow
        }

        return totalVotingPower;
    }

    function propose(
        address proposerAddress,
        string calldata metadataUri,
        address executionStrategy,
        address[] calldata usedVotingStrategies,
        bytes[] calldata userVotingStrategyParams,
        bytes calldata executionParams
    ) external {
        _assertValidAuthenticator();
        _assertValidExecutionStrategy(executionStrategy);
        require(
            usedVotingStrategies.length == userVotingStrategyParams.length,
            "Used Strategies and Used Strategies Parameters length mismatch"
        );

        uint32 snapshotTimestamp = uint32(block.timestamp);

        uint256 votingPower = _getCumulativeVotingPower(
            snapshotTimestamp,
            proposerAddress,
            usedVotingStrategies,
            userVotingStrategyParams
        );
        require(votingPower >= proposalThreshold, "Insufficient voting power");

        // TODO: use SafeMath
        uint32 startTimestamp = snapshotTimestamp + votingDelay;
        uint32 minEndtimestamp = startTimestamp + minVotingDuration;
        uint32 maxEndtimestamp = startTimestamp + maxVotingDuration;

        // TODO: should we use encode or encodePacked?
        bytes32 executionHash = keccak256(abi.encodePacked(executionParams));

        // TODO: Is memory correct here?
        Proposal memory proposal = Proposal(
            quorum,
            snapshotTimestamp,
            startTimestamp,
            minEndtimestamp,
            maxEndtimestamp,
            executionStrategy,
            executionHash
        );

        proposalRegistry[nextProposalNonce] = proposal;
        emit ProposalCreated(nextProposalNonce, proposerAddress, proposal, metadataUri, executionParams);

        nextProposalNonce++;
    }
}
