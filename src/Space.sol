// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/console2.sol";
import "src/interfaces/IVotingStrategy.sol";
import "src/types.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// TODO: Ownable? Eip712?
contract Space is Ownable {
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
    // This needs to be an array because a mapping would limit a space to only one use per voting strategy contract.
    address[] private votingStrategies;
    bytes[] private votingStrategiesParams;
    uint256 private nextProposalNonce;
    mapping(uint256 => Proposal) private proposalRegistry;
    mapping(uint256 => bool) private executedProposals;

    constructor(
        address owner,
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
        require(_authenticators.length > 0, "Authenticators array empty");
        require(_executionStrategies.length > 0, "Execution Strategies array empty");

        // TODO: call _addVotingStrategies and remove
        require(_votingStrategies.length > 0, "Voting Strategies array empty");
        require(
            _votingStrategies.length == _votingStrategiesParams.length,
            "Strategies and Strategies Parameters length mismatch"
        );

        transferOwnership(owner);

        votingDelay = _votingDelay;
        minVotingDuration = _minVotingDuration;
        maxVotingDuration = _maxVotingDuration;
        proposalThreshold = _proposalThreshold;
        quorum = _quorum;

        // TODO: find a way to call [`_addVotingStrategies`]
        for (uint i = 0; i < _votingStrategies.length; i++) {
            // See comment in `_addVotingStrategies`
            require(_votingStrategies[i] != address(0), "Invalid Voting Strategy address");
            votingStrategies.push(_votingStrategies[i]);
            votingStrategiesParams.push(_votingStrategiesParams[i]);
        }

        for (uint i = 0; i < _executionStrategies.length; i++) {
            executionStrategies[_executionStrategies[i]] = true;
        }
        for (uint i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = true;
        }

        nextProposalNonce = 1;
    }

    function _addVotingStrategies(
        address[] calldata _votingStrategies,
        bytes[] calldata _votingStrategiesParams
    ) private {
        require(_votingStrategies.length > 0, "Voting Strategies array empty");
        require(
            _votingStrategies.length == _votingStrategiesParams.length,
            "Strategies and Strategies Parameters length mismatch"
        );

        for (uint i = 0; i < _votingStrategies.length; i++) {
            // A voting strategy set to 0 is used to indicate that the voting strategy is no longer active,
            // so we need to prevent the user from adding a null invalid strategy address.
            require(_votingStrategies[i] != address(0), "Invalid Voting Strategy address");
            votingStrategies.push(_votingStrategies[i]);
            votingStrategiesParams.push(_votingStrategiesParams[i]);
        }

        // TODO: emit an event
    }

    function _removeVotingStrategies(uint256[] calldata indicesToRemove) private {
        for (uint i = 0; i < indicesToRemove.length; i++) {
            votingStrategies[indicesToRemove[i]] = address(0);
            votingStrategiesParams[indicesToRemove[i]] = new bytes(0);
        }
        // TODO: emit an event
    }

    function _assertValidAuthenticator() private view {
        require(authenticators[msg.sender], "Invalid Authenticator");
    }

    function _assertValidExecutionStrategy(address executionStrategy) private view {
        require(executionStrategies[executionStrategy], "Invalid Execution Strategy");
    }

    // No way to declare a mapping in memory so we need to use an array and go for O(n^2)...
    function _assertNoDuplicates(uint[] memory arr) private pure {
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
        uint[] calldata usedVotingStrategiesIndices,
        bytes[] calldata userVotingStrategyParams
    ) private view returns (uint256) {
        // Make sure there are no duplicates to avoid an attack where people double count a voting strategy
        _assertNoDuplicates(usedVotingStrategiesIndices);

        uint256 totalVotingPower = 0;
        for (uint i = 0; i < usedVotingStrategiesIndices.length; i++) {
            uint index = usedVotingStrategiesIndices[i];
            address strategyAddress = votingStrategies[index];
            require(strategyAddress != address(0), "Invalid Voting Strategy Index");
            IVotingStrategy strategy = IVotingStrategy(strategyAddress);
            totalVotingPower += strategy.getVotingPower(
                timestamp,
                userAddress,
                votingStrategiesParams[index],
                userVotingStrategyParams[i]
            );
            // TODO: use SafeMath, check overflow
        }

        return totalVotingPower;
    }

    function setQuorum(uint256 _quorum) external onlyOwner {
        quorum = _quorum;
        // TODO emit event
    }

    function setProposalThreshold(uint256 _threshold) external onlyOwner {
        proposalThreshold = _threshold;
        // TODO emit event
    }

    function setMetadataUri(string calldata _metadataUri) external onlyOwner {
        // TODO emit event
    }

    function setVotingDelay(uint32 _votingDelay) external onlyOwner {
        votingDelay = _votingDelay;
        // TODO: emit event
        // TODO: check it's not too big?
    }

    function addVotingStrategies(
        address[] calldata _votingStrategies,
        bytes[] calldata _votingStrategiesParams
    ) external onlyOwner {
        _addVotingStrategies(_votingStrategies, _votingStrategiesParams);
    }

    function removeVotingStrategies(uint256[] calldata indicesToRemove) external onlyOwner {
        _removeVotingStrategies(indicesToRemove);
    }

    function propose(
        address proposerAddress,
        string calldata metadataUri,
        address executionStrategy,
        uint256[] calldata usedVotingStrategiesIndices,
        bytes[] calldata userVotingStrategyParams,
        bytes calldata executionParams
    ) external {
        _assertValidAuthenticator();
        _assertValidExecutionStrategy(executionStrategy);
        require(
            usedVotingStrategiesIndices.length == userVotingStrategyParams.length,
            "Used Strategies and Used Strategies Parameters length mismatch"
        );

        uint32 snapshotTimestamp = uint32(block.timestamp);

        uint256 votingPower = _getCumulativeVotingPower(
            snapshotTimestamp,
            proposerAddress,
            usedVotingStrategiesIndices,
            userVotingStrategyParams
        );
        require(votingPower >= proposalThreshold, "Proposal threshold not reached");

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
