import { HardhatUserConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";

import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";

import "@matterlabs/hardhat-zksync-verify";

// dynamically changes endpoints for local tests
const zkSyncLocalTestnet = {
  url: "http://localhost:3050",
  ethNetwork: "http://localhost:8545",
  zksync: true,
};

const zkSyncTestnet = {
  url: "https://zksync2-testnet.zksync.dev",
  ethNetwork: "goerli",
  zksync: true,
  // contract verification endpoint
  verifyURL:
    "https://zksync2-testnet-explorer.zksync.dev/contract_verification",
};

const config: HardhatUserConfig = {
  zksolc: {
    version: "1.3.13",
    settings: {},
  },
  defaultNetwork: "zkSyncLocalTestnet",
  networks: {
    hardhat: {
      zksync: false,
    },
    zkSyncTestnet,
    zkSyncLocalTestnet,
  },
  solidity: {
    version: "0.8.18",
  },
  paths: {
    sources: "./src",
    tests: "./test/zksync",
  }
};

export default config;