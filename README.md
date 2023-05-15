[![codecov](https://codecov.io/github/snapshot-labs/sx-evm/branch/main/graph/badge.svg?token=BZ4XKYU3FT)](https://app.codecov.io/gh/snapshot-labs/sx-evm)
[![ci](https://github.com/snapshot-labs/sx-evm/actions/workflows/ci.yml/badge.svg)](https://github.com/snapshot-labs/sx-evm/actions/workflows/ci.yml)

# Snapshot X

An EVM implementation of the Snapshot X Protocol. Refer to the [documentation](https://docs.snapshotx.xyz) for more
information.

## Contracts Blueprint

```ml
contracts
├─ starknet
├─ Authenticators
│  ├─ EthTx.cairo — "Authenticate user via an Ethereum transaction"
│  ├─ EthSig.cairo — "Authenticate user via an Ethereum signature"
│  ├─ EthSigSessionKey.cairo — "Authenticate user via a Session key which has been authorized with an Ethereum signature"
│  ├─ EthTxSessionKey.cairo — "Authenticate user via a Session key which has been authorized with an Ethereum transaction"
│  ├─ StarkTx.cairo — "Authenticate user via a StarkNet transaction"
│  ├─ StarkSig.cairo — "Authenticate user via a Starknet signature"
│  └─ Vanilla.cairo — "Dummy authentication"
├─ VotingStrategies
│  ├─ EthBalanceOf.cairo — "Voting power found from Ethereum token balances"
│  ├─ Vanilla.cairo — "Voting power of 1 for every user"
│  └─ Whitelist.cairo — "Predetermined voting power for members in a whitelist, otherwise zero"
├─ ExecutionStrategies
│  ├─ Vanilla.cairo — "Dummy execution"
│  └─ EthRelayer.cairo — "Strategy to execute proposal transactions on Ethereum"
├─ Interfaces
│  ├─ IExecutionStrategy.cairo — "Interface for all execution strategies"
│  ├─ IVotingStrategy.cairo — "Interface for all voting strategies"
│  ├─ ISpaceAccount.cairo — "Interface for the space contract"
│  └─ ISpaceFactory.cairo — "Interface for the space factory"
├─ lib
│  ├─ array_utils.cairo — "A library containing various array utilities"
│  ├─ choice.cairo — "The set of choices one can make for a vote"
│  ├─ eip712.cairo — "Library for Ethereum typed data signature verification"
│  ├─ eth_tx.cairo — "Libary for authenticating users via an Ethereum transaction"
│  ├─ execute.cairo — "contract call wrapper"
│  ├─ general_address.cairo — "Generic address type"
│  ├─ math_utils.cairo — "A library containing various math utilities"
│  ├─ proposal.cairo — "Proposal metadata type"
│  ├─ proposal_info.cairo — "Proposal vote data type"
│  ├─ proposal_outcome.cairo — "The set of proposal outcomes"
│  ├─ slot_key.cairo — "Library for finding EVM slot keys"
│  ├─ voting.cairo — "Core library that implements the logic for the space contract"
│  ├─ vote.cairo — "User vote data type"
│  ├─ session_key.cairo — "Library to handle session key logic"
│  ├─ stark_eip191.cairo — "Library for Starknet typed data signature verification"
│  ├─ single_slot_proof.cairo — "Library to enable values from the Ethereum state to be used for voting power"
│  └─ timestamp - "Library to handle timestamp to block number conversions within the single slot proof library"
├─ SpaceAccount.cairo - "The base contract for each Snapshot X space"
└─ SpaceFactory.cairo - "Handles the deployment and tracking of Space contracts"
```
