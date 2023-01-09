// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/console2.sol";
import "src/interfaces/IVotingStrategy.sol";
// import "src/interfaces/ISpace.sol"; TODO: add this later when everything has been impl
import "src/interfaces/space/ISpaceEvents.sol";
import "src/types.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author  SnapshotLabs
 * @title   Space Contract.
 * @notice  Logic and bookkeeping contract.
 */
contract Space is ISpaceEvents, Ownable {
    // Maximum duration a proposal can last.
    uint32 public maxVotingDuration;
    // Minimum duration a proposal can last.
    uint32 public minVotingDuration;
    // Next proposal nonce, increased by one everytime a new proposal is created.
    uint256 public nextProposalNonce;
    // Minimum voting power required by a user to create a new proposal (used to prevent proposal spamming).
    uint256 public proposalThreshold;
    // Total voting power that needs to participate to a vote for a vote to be considered valid.
    uint256 public quorum;
    // Delay between when the proposal is created and when the voting period starts for this proposal.
    uint32 public votingDelay;

    // Array of available voting strategies that users can use to determine their voting power.
    /// @dev This needs to be an array because a mapping would limit a space to only one use per
    ///      voting strategy contract.
    VotingStrategy[] private votingStrategies;

    // Mapping of allowed execution strategies.
    mapping(address => bool) private executionStrategies;
    // Mapping of allowed authenticators.
    mapping(address => bool) private authenticators;
    // Mapping of all `Proposal`s of this space (past and present).
    mapping(uint256 => Proposal) private proposalRegistry;
    // Mapping to keep track of whether a proposal has been executed or not.
    mapping(uint256 => bool) private executedProposals;

    // ------------------------------------
    // |                                  |
    // |          CONSTRUCTOR             |
    // |                                  |
    // ------------------------------------

    constructor(
        address _owner,
        uint32 _votingDelay,
        uint32 _minVotingDuration,
        uint32 _maxVotingDuration,
        uint256 _proposalThreshold,
        uint256 _quorum,
        VotingStrategy[] memory _votingStrategies,
        address[] memory _authenticators,
        address[] memory _executionStrategies
    ) {
        require(
            _minVotingDuration <= _maxVotingDuration,
            "Min duration should be smaller than or equal to max duration"
        );
        require(_authenticators.length > 0, "Authenticators array empty");
        require(_executionStrategies.length > 0, "Execution Strategies array empty");

        // TODO: call _addVotingStrategies and remove
        require(_votingStrategies.length > 0, "Voting Strategies array empty");

        transferOwnership(_owner);

        votingDelay = _votingDelay;
        minVotingDuration = _minVotingDuration;
        maxVotingDuration = _maxVotingDuration;
        proposalThreshold = _proposalThreshold;
        quorum = _quorum;

        // TODO: find a way to call [`_addVotingStrategies`] (problem because of `calldata` vs `memory`)
        for (uint256 i = 0; i < _votingStrategies.length; i++) {
            // See comment in `_addVotingStrategies`
            require(_votingStrategies[i].addy != address(0), "Invalid Voting Strategy address");
            votingStrategies.push(_votingStrategies[i]);
        }

        for (uint256 i = 0; i < _executionStrategies.length; i++) {
            executionStrategies[_executionStrategies[i]] = true;
        }

        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = true;
        }
        // TODO: decide if we wish to emit the events or not
        // emit VotingStrategiesAdded(_votingStrategies, _votingStrategiesParams);
        // emit ExecutionStrategiesAdded(_executionStrategies);
        // emit AuthenticatorsAdded(_authenticators);

        nextProposalNonce = 1;
    }

    // ------------------------------------
    // |                                  |
    // |            INTERNAL              |
    // |                                  |
    // ------------------------------------

    /**
     * @notice  Internal function to add voting strategies.
     * @dev     `_votingStrategies` should not be set to `0`.
     * @param   _votingStrategies  Array of voting strategies to add.
     */
    function _addVotingStrategies(VotingStrategy[] calldata _votingStrategies) internal {
        require(_votingStrategies.length > 0, "Voting Strategies array empty");

        for (uint256 i = 0; i < _votingStrategies.length; i++) {
            // A voting strategy set to 0 is used to indicate that the voting strategy is no longer active,
            // so we need to prevent the user from adding a null invalid strategy address.
            require(_votingStrategies[i].addy != address(0), "Invalid Voting Strategy address");
            votingStrategies.push(_votingStrategies[i]);
        }

        emit VotingStrategiesAdded(_votingStrategies);
    }

    /**
     * @notice  Internal function to remove voting strategies.
     * @dev     Does not shrink the array but simply sets the values to 0.
     * @param   indicesToRemove  Indices of the strategies to remove.
     */
    function _removeVotingStrategies(uint256[] calldata indicesToRemove) internal {
        for (uint256 i = 0; i < indicesToRemove.length; i++) {
            votingStrategies[indicesToRemove[i]].addy = address(0);
            votingStrategies[indicesToRemove[i]].params = new bytes(0);
        }

        emit VotingStrategiesRemoved(indicesToRemove);
    }

    /**
     * @notice  Internal function to add authenticators.
     * @param   _authenticators  Array of authenticators to add.
     */
    function _addAuthenticators(address[] calldata _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = true;
        }
        emit AuthenticatorsAdded(_authenticators);
    }

    /**
     * @notice  Internal function to remove authenticators.
     * @param   _authenticators  Array of authenticators to remove.
     */
    function _removeAuthenticators(address[] calldata _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = false;
        }
        emit AuthenticatorsRemoved(_authenticators);
    }

    /**
     * @notice  Internal function to add exection strategies.
     * @param   _executionStrategies  Array of exectuion strategies to add.
     */
    function _addExecutionStrategies(address[] calldata _executionStrategies) internal {
        for (uint256 i = 0; i < _executionStrategies.length; i++) {
            executionStrategies[_executionStrategies[i]] = true;
        }
        emit ExecutionStrategiesAdded(_executionStrategies);
    }

    /**
     * @notice  Internal function to remove execution strategies.
     * @param   _executionStrategies  Array of execution strategies to remove.
     */
    function _removeExecutionStrategies(address[] calldata _executionStrategies) internal {
        for (uint256 i = 0; i < _executionStrategies.length; i++) {
            executionStrategies[_executionStrategies[i]] = false;
        }
        emit ExecutionStrategiesRemoved(_executionStrategies);
    }

    /**
     * @notice  Internal function to ensure `msg.sender` is in the list of allowed authenticators.
     */
    function _assertValidAuthenticator() internal view {
        require(authenticators[msg.sender], "Invalid Authenticator");
    }

    /**
     * @notice  Internal function to ensure `executionStrategy` is in the list of allowed execution strategies.
     * @param   executionStrategy  The execution strategy to check.
     */
    function _assertValidExecutionStrategy(address executionStrategy) internal view {
        require(executionStrategies[executionStrategy], "Invalid Execution Strategy");
    }

    /**
     * @notice  Internal function to ensure there are no duplicates in an array of uints.
     * @dev     No way to declare a mapping in memory so we need to use an array and go for O(n^2)...
     * @param   arr  Array to check for duplicates.
     */
    function _assertNoDuplicates(uint[] memory arr) internal pure {
        if (arr.length > 0) {
            for (uint256 i = 0; i < arr.length - 1; i++) {
                for (uint256 j = i + 1; j < arr.length; j++) {
                    require(arr[i] != arr[j], "Duplicates found"); // TODO: should we use a `if` to reduce gas cost?
                }
            }
        }
    }

    /**
     * @notice  Internal function that will loop over the used voting strategies and
                return the cumulative voting power of a user.
     * @dev     
     * @param   timestamp  Timestamp of the snapshot.
     * @param   userAddress  Address for which to compute the voting power.
     * @param   usedVotingStrategiesIndices  Indices of the desired voting strategies to check.
     * @param   userVotingStrategyParams  Associated user parameters.
     * @return  uint256  The total voting power of a user (over those specified voting strategies).
     */
    function _getCumulativeVotingPower(
        uint32 timestamp,
        address userAddress,
        uint[] calldata usedVotingStrategiesIndices,
        bytes[] calldata userVotingStrategyParams
    ) internal view returns (uint256) {
        // Ensure there are no duplicates to avoid an attack where people double count a voting strategy
        _assertNoDuplicates(usedVotingStrategiesIndices);

        uint256 totalVotingPower = 0;
        for (uint256 i = 0; i < usedVotingStrategiesIndices.length; i++) {
            uint256 index = usedVotingStrategiesIndices[i];
            VotingStrategy memory votingStrategy = votingStrategies[index];
            // A strategyAddress set to 0 indicates that this address has already been removed and is
            // no longer a valid voting strategy. See `_removeVotingStrategies`.
            require(votingStrategy.addy != address(0), "Invalid Voting Strategy Index");
            IVotingStrategy strategy = IVotingStrategy(votingStrategy.addy);
            totalVotingPower += strategy.getVotingPower(
                timestamp,
                userAddress,
                votingStrategy.params,
                userVotingStrategyParams[i]
            );
            // TODO: use SafeMath, check overflow
        }

        return totalVotingPower;
    }

    // ------------------------------------
    // |                                  |
    // |             SETTERS              |
    // |                                  |
    // ------------------------------------

    function setMaxVotingDuration(uint32 _maxVotingDuration) external onlyOwner {
        require(_maxVotingDuration >= minVotingDuration, "Max Duration must be bigger than Min Duration");
        emit MaxVotingDurationUpdated(maxVotingDuration, _maxVotingDuration);

        maxVotingDuration = _maxVotingDuration;
    }

    function setMinVotingDuration(uint32 _minVotingDuration) external onlyOwner {
        require(_minVotingDuration <= maxVotingDuration, "Min Duration must be smaller than Max Duration");

        emit MinVotingDurationUpdated(minVotingDuration, _minVotingDuration);

        minVotingDuration = _minVotingDuration;
    }

    function setMetadataUri(string calldata _metadataUri) external onlyOwner {
        emit MetadataUriUpdated(_metadataUri);
    }

    function setProposalThreshold(uint256 _threshold) external onlyOwner {
        emit ProposalThresholdUpdated(proposalThreshold, _threshold);

        proposalThreshold = _threshold;
    }

    function setQuorum(uint256 _quorum) external onlyOwner {
        emit QuorumUpdated(quorum, _quorum);
        quorum = _quorum;
    }

    function setVotingDelay(uint32 _votingDelay) external onlyOwner {
        emit VotingDelayUpdated(votingDelay, _votingDelay);

        votingDelay = _votingDelay;
        // TODO: check it's not too big?
    }

    function addVotingStrategies(VotingStrategy[] calldata _votingStrategies) external onlyOwner {
        _addVotingStrategies(_votingStrategies);
    }

    function removeVotingStrategies(uint256[] calldata indicesToRemove) external onlyOwner {
        _removeVotingStrategies(indicesToRemove);
    }

    function addAuthenticators(address[] calldata _authenticators) external onlyOwner {
        _addAuthenticators(_authenticators);
    }

    function removeAuthenticators(address[] calldata _authenticators) external onlyOwner {
        _removeAuthenticators(_authenticators);
    }

    function addExecutionStrategies(address[] calldata _executionStrategies) external onlyOwner {
        _addExecutionStrategies(_executionStrategies);
    }

    function removeExecutionStrategies(address[] calldata _executionStrategies) external onlyOwner {
        _removeExecutionStrategies(_executionStrategies);
    }

    // ------------------------------------
    // |                                  |
    // |             GETTERS              |
    // |                                  |
    // ------------------------------------

    function getProposalInfo(uint256 proposalId) external view returns (Proposal memory) {
        Proposal memory proposal = proposalRegistry[proposalId];

        // startTimestamp cannot be set to 0 when a proposal is created,
        // so if proposal.startTimestamp is 0 it means this proposal does not exist
        // and hence `proposalId` is invalid.
        require(proposal.startTimestamp != 0, "Invalid proposalId");

        // TODO: maybe get proposal status (executed or not?)
        return (proposal);
    }

    // ------------------------------------
    // |                                  |
    // |             CORE                 |
    // |                                  |
    // ------------------------------------

    /**
     * @notice  Creates a proposal.
     * @param   proposerAddress  The address of the proposal creator.
     * @param   metadataUri  The metadata URI for the proposal.
     * @param   executionStrategy  The execution contract to use for this proposal.
     * @param   usedVotingStrategiesIndices  Indices to use to compute the proposer voting power.
     * @param   userVotingStrategyParams  Associated parameters to use for computing the proposer voting power.
     * @param   executionParams  The execution parameters (used if a proposal gets accepted).
     */
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
        uint32 minEndTimestamp = startTimestamp + minVotingDuration;
        uint32 maxEndTimestamp = startTimestamp + maxVotingDuration;

        // TODO: should we use encode or encodePacked?
        bytes32 executionHash = keccak256(abi.encodePacked(executionParams));

        Proposal memory proposal = Proposal(
            quorum,
            snapshotTimestamp,
            startTimestamp,
            minEndTimestamp,
            maxEndTimestamp,
            executionStrategy,
            executionHash
        );

        proposalRegistry[nextProposalNonce] = proposal;
        emit ProposalCreated(nextProposalNonce, proposerAddress, proposal, metadataUri, executionParams);

        nextProposalNonce++;
    }
}
