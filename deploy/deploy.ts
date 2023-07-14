import fs from 'fs';
import { Wallet, Provider, utils } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

// load env file
import dotenv from "dotenv";
dotenv.config();

// load wallet private key from env file
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

if (!PRIVATE_KEY) throw "⛔️ Private key not detected! Add it to the .env file!";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  // Initialize the wallet.
  // Todo query network url from hardhat config
  const provider = new Provider("https://zksync2-testnet.zksync.dev")
  const wallet = new Wallet(PRIVATE_KEY, provider);
  // Create deployer object and load the artifact of the contract you want to deploy.
  const deployer = new Deployer(hre, wallet);

  const vanillaAuthenticatorArtifact = await deployer.loadArtifact("VanillaAuthenticator");
  const ethTxAuthenticatorArtifact = await deployer.loadArtifact("EthTxAuthenticator");
  const ethSigAuthenticatorArtifact = await deployer.loadArtifact("EthSigAuthenticator");

  const vanillaVotingStrategyArtifact = await deployer.loadArtifact("VanillaVotingStrategy");
  const compVotingStrategyArtifact = await deployer.loadArtifact("CompVotingStrategy");
  const ozVotesVotingStrategyArtifact = await deployer.loadArtifact("OZVotesVotingStrategy");
  const whitelistVotingStrategyArtifact = await deployer.loadArtifact("WhitelistVotingStrategy");

  const vanillaProposalValidationStrategyArtifact = await deployer.loadArtifact("VanillaProposalValidationStrategy");
  const propositionPowerProposalValidationStrategyArtifact = await deployer.loadArtifact("PropositionPowerProposalValidationStrategy");
  const activeProposalsLimiterProposalValidationStrategyArtifact = await deployer.loadArtifact("ActiveProposalsLimiterProposalValidationStrategy");
  const propositionPowerAndActiveProposalsLimiterProposalValidationStrategyArtifact = await deployer.loadArtifact("PropositionPowerAndActiveProposalsLimiterValidationStrategy");

  const avatarExecutionStrategyArtifact = await deployer.loadArtifact("AvatarExecutionStrategy");
  const timelockExecutionStrategyArtifact = await deployer.loadArtifact("TimelockExecutionStrategy");
  const optimisticTimelockExecutionStrategyArtifact = await deployer.loadArtifact("OptimisticTimelockExecutionStrategy");
  const compTimelockCompatibleExecutionStrategyArtifact = await deployer.loadArtifact("CompTimelockCompatibleExecutionStrategy");
  const optimisticCompTimelockCompatibleExecutionStrategyArtifact = await deployer.loadArtifact("OptimisticCompTimelockCompatibleExecutionStrategy");

  const spaceArtifact = await deployer.loadArtifact("Space");
  const proxyFactoryArtifact = await deployer.loadArtifact("ProxyFactory");

  const ethSigAuthenticatorConstructorArgs = ["snapshot-x", "1.0.0"];
  const avatarExecutionStrategyConstructorArgs = ["0x0000000000000000000000000000000000000001", "0x0000000000000000000000000000000000000001", [], "0x0"];
  const compTimelockCompatibleExecutionStrategyConstructorArgs = ["0x0000000000000000000000000000000000000001", "0x0000000000000000000000000000000000000001", [], "0x0", "0x0000000000000000000000000000000000000000"];
  const optimisticCompTimelockCompatibleExecutionStrategyConstructorArgs = ["0x0000000000000000000000000000000000000001", "0x0000000000000000000000000000000000000001", [], "0x0", "0x0000000000000000000000000000000000000000"];

  const vanillaAuthenticatorContract = await deployer.deploy(vanillaAuthenticatorArtifact, []);
  console.log(`${vanillaAuthenticatorArtifact.contractName} was deployed to ${vanillaAuthenticatorContract.address}`);

  const ethTxAuthenticatorContract = await deployer.deploy(ethTxAuthenticatorArtifact, []);
  console.log(`${ethTxAuthenticatorArtifact.contractName} was deployed to ${ethTxAuthenticatorContract.address}`);

  const ethSigAuthenticatorContract = await deployer.deploy(ethSigAuthenticatorArtifact, ethSigAuthenticatorConstructorArgs);
  console.log(`${ethSigAuthenticatorArtifact.contractName} was deployed to ${ethSigAuthenticatorContract.address}`);

  const vanillaVotingStrategyContract = await deployer.deploy(vanillaVotingStrategyArtifact, []);
  console.log(`${vanillaVotingStrategyArtifact.contractName} was deployed to ${vanillaVotingStrategyContract.address}`);

  const compVotingStrategyContract = await deployer.deploy(compVotingStrategyArtifact, []);
  console.log(`${compVotingStrategyArtifact.contractName} was deployed to ${compVotingStrategyContract.address}`);

  const ozVotesVotingStrategyContract = await deployer.deploy(ozVotesVotingStrategyArtifact, []);
  console.log(`${ozVotesVotingStrategyArtifact.contractName} was deployed to ${ozVotesVotingStrategyContract.address}`);

  const whitelistVotingStrategyContract = await deployer.deploy(whitelistVotingStrategyArtifact, []);
  console.log(`${whitelistVotingStrategyArtifact.contractName} was deployed to ${whitelistVotingStrategyContract.address}`);

  const vanillaProposalValidationStrategyContract = await deployer.deploy(vanillaProposalValidationStrategyArtifact, []);
  console.log(`${vanillaProposalValidationStrategyArtifact.contractName} was deployed to ${vanillaProposalValidationStrategyContract.address}`);

  const propositionPowerProposalValidationStrategyContract = await deployer.deploy(propositionPowerProposalValidationStrategyArtifact, []);
  console.log(`${propositionPowerProposalValidationStrategyArtifact.contractName} was deployed to ${propositionPowerProposalValidationStrategyContract.address}`);

  const activeProposalsLimiterProposalValidationStrategyContract = await deployer.deploy(activeProposalsLimiterProposalValidationStrategyArtifact, []);
  console.log(`${activeProposalsLimiterProposalValidationStrategyArtifact.contractName} was deployed to ${activeProposalsLimiterProposalValidationStrategyContract.address}`);
  
  const propositionPowerAndActiveProposalsLimiterValidationStrategyContract = await deployer.deploy(propositionPowerAndActiveProposalsLimiterValidationStrategyArtifact, []);
  console.log(`${propositionPowerAndActiveProposalsLimiterValidationStrategyArtifact.contractName} was deployed to ${propositionPowerAndActiveProposalsLimiterValidationStrategyContract.address}`);

  const avatarExecutionStrategyContract = await deployer.deploy(avatarExecutionStrategyArtifact, avatarExecutionStrategyConstructorArgs);
  console.log(`${avatarExecutionStrategyArtifact.contractName} was deployed to ${avatarExecutionStrategyContract.address}`);

  const timelockExecutionStrategyContract = await deployer.deploy(timelockExecutionStrategyArtifact, []);
  console.log(`${timelockExecutionStrategyArtifact.contractName} was deployed to ${timelockExecutionStrategyContract.address}`);

  const optimisticTimelockExecutionStrategyContract = await deployer.deploy(optimisticTimelockExecutionStrategyArtifact, []);
  console.log(`${optimisticTimelockExecutionStrategyArtifact.contractName} was deployed to ${optimisticTimelockExecutionStrategyContract.address}`);

  const compTimelockCompatibleExecutionStrategyContract = await deployer.deploy(compTimelockCompatibleExecutionStrategyArtifact, compTimelockCompatibleExecutionStrategyConstructorArgs);
  console.log(`${compTimelockCompatibleExecutionStrategyArtifact.contractName} was deployed to ${compTimelockCompatibleExecutionStrategyContract.address}`)

  const optimisticCompTimelockCompatibleExecutionStrategyContract = await deployer.deploy(optimisticCompTimelockCompatibleExecutionStrategyArtifact, optimisticCompTimelockCompatibleExecutionStrategyConstructorArgs);
  console.log(`${optimisticCompTimelockCompatibleExecutionStrategyArtifact.contractName} was deployed to ${optimisticCompTimelockCompatibleExecutionStrategyContract.address}`)

  const spaceContract = await deployer.deploy(spaceArtifact, []);
  console.log(`${spaceArtifact.contractName} was deployed to ${spaceContract.address}`);

  // master space initializer
  await wallet.sendTransaction({
    to: spaceContract.address,
    data: "0xf8b669d600000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000002c000000000000000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001"
  })

  const proxyFactoryContract = await deployer.deploy(proxyFactoryArtifact, []);
  console.log(`${proxyFactoryArtifact.contractName} was deployed to ${proxyFactoryContract.address}`);

  const deployment = JSON.parse(fs.readFileSync('./deployments/zksync.json').toString());
  console.log(deployment.VanillaAuthenticator);
  try {
    await hre.run("verify:verify", {
      address: deployment.VanillaAuthenticator,
      contract: "src/authenticators/VanillaAuthenticator.sol:VanillaAuthenticator",
      constructorArguments: []
    });
  } catch (e) {}

  try {
    await hre.run("verify:verify", {
      address: deployment.EthTxAuthenticator,
      contract: "src/authenticators/EthTxAuthenticator.sol:EthTxAuthenticator",
      constructorArguments: []
    });
  } catch (e) {}

  try {
    await hre.run("verify:verify", {
      address: deployment.EthSigAuthenticator,
      contract: "src/authenticators/EthSigAuthenticator.sol:EthSigAuthenticator",
      constructorArguments: ethSigAuthenticatorConstructorArgs
    });
  } catch (e) {}

  try {
    await hre.run("verify:verify", {
      address: deployment.VanillaVotingStrategy,
      contract: "src/voting-strategies/VanillaVotingStrategy.sol:VanillaVotingStrategy",
      constructorArguments: []
    });
  } catch (e) {}

  try {
    await hre.run("verify:verify", {
      address: deployment.CompVotingStrategy,
      contract: "src/voting-strategies/CompVotingStrategy.sol:CompVotingStrategy",
      constructorArguments: []
    });
  } catch (e) {}

  try {
    await hre.run("verify:verify", {
      address:  deployment.OZVotesVotingStrategy,
      contract: "src/voting-strategies/OZVotesVotingStrategy.sol:OZVotesVotingStrategy",
      constructorArguments: []
    });
  } catch (e) {}

  try {
    await hre.run("verify:verify", {
    address: deployment.WhitelistVotingStrategy,
    contract: "src/voting-strategies/WhitelistVotingStrategy.sol:WhitelistVotingStrategy",
    constructorArguments: []
  });
  } catch (e) {}

  try {
    await  hre.run("verify:verify", {
      address: deployment.VanillaProposalValidationStrategy,
      contract: "src/proposal-validation-strategies/VanillaProposalValidationStrategy.sol:VanillaProposalValidationStrategy",
      constructorArguments: []
    });
  } catch (e) {}

  try {
   await hre.run("verify:verify", {
    address: deployment.PropositionPowerProposalValidationStrategy,
    contract: "src/proposal-validation-strategies/PropositionPowerProposalValidationStrategy.sol:PropositionPowerProposalValidationStrategy",
    constructorArguments: []
  });
} catch (e) {}

  try {
    await hre.run("verify:verify", {
    address: deployment.ActiveProposalsLimiterProposalValidationStrategy,
    contract: "src/proposal-validation-strategies/ActiveProposalsLimiterProposalValidationStrategy.sol:ActiveProposalsLimiterProposalValidationStrategy",
    constructorArguments: []
  });
} catch (e) {}

  try {
    await hre.run("verify:verify", {
    address: deployment.PropositionPowerAndActiveProposalsLimiterProposalValidationStrategy,
    contract: "src/proposal-validation-strategies/PropositionPowerAndActiveProposalsLimiterValidationStrategy.sol:PropositionPowerAndActiveProposalsLimiterValidationStrategy",
    constructorArguments: []
  });
} catch (e) {}

  try {
    await hre.run("verify:verify", {
    address: deployment.AvatarExecutionStrategy,
    contract: "src/execution-strategies/AvatarExecutionStrategy.sol:AvatarExecutionStrategy",
    constructorArguments: avatarExecutionStrategyConstructorArgs
  });
} catch (e) {}

  try {
    await hre.run("verify:verify", {
    address: deployment.TimelockExecutionStrategy,
    contract: "src/execution-strategies/timelocks/TimelockExecutionStrategy.sol:TimelockExecutionStrategy",
    constructorArguments: []
  });
} catch (e) {}  

  try {
    await hre.run("verify:verify", {
    address: deployment.OptimisticTimelockExecutionStrategy,
    contract: "src/execution-strategies/timelocks/OptimisticTimelockExecutionStrategy.sol:OptimisticTimelockExecutionStrategy",
    constructorArguments: []
  });
} catch (e) {}  

  try {
    await hre.run("verify:verify", {
    address: deployment.CompTimelockCompatibleExecutionStrategy,
    contract: "src/execution-strategies/timelocks/CompTimelockCompatibleExecutionStrategy.sol:CompTimelockCompatibleExecutionStrategy",
    constructorArguments: compTimelockCompatibleExecutionStrategyConstructorArgs
  });
} catch (e) {}

  try {
    await hre.run("verify:verify", {
    address: deployment.OptimisticCompTimelockCompatibleExecutionStrategy,
    contract: "src/execution-strategies/timelocks/OptimisticCompTimelockCompatibleExecutionStrategy.sol:OptimisticCompTimelockCompatibleExecutionStrategy",
    constructorArguments: optimisticCompTimelockCompatibleExecutionStrategyConstructorArgs
  });
} catch (e) {}

try {
  await hre.run("verify:verify", {
    address: spaceContract.address,
    contract: "src/Space.sol:Space",
    constructorArguments: []
  });
} catch (e) {}

  try {
    await hre.run("verify:verify", {
      address: proxyFactoryContract.address,
      contract: "src/ProxyFactory.sol:ProxyFactory",
      constructorArguments: []
    });
  } catch (e) {}
}