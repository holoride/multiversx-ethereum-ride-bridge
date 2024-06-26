import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "hardhat-log-remover";
import "hardhat-tracer";
import "hardhat-abi-exporter";
import "solidity-coverage";

import "./tasks/accounts";
import "./tasks/clean";
import "./tasks/add-to-whitelist";
import "./tasks/mint-test-tokens";
import "./tasks/set-quorum";
import "./tasks/approve";
import "./tasks/deposit";
import "./tasks/set-min-amount";
import "./tasks/set-max-amount";
import "./tasks/set-batch-block-limit";
import "./tasks/set-batch-size";
import "./tasks/fill-nonce-gap";
import "./tasks/add-relayer";
import "./tasks/remove-relayer";
import "./tasks/pause-bridge";
import "./tasks/unpause-bridge";
import "./tasks/pause-safe";
import "./tasks/unpause-safe";
import "./tasks/init-supply";
import "./tasks/remove-from-whitelist";
import "./tasks/recover-lost-funds";
import "./tasks/get-batch";
import "./tasks/get-batch-deposits";
import "./tasks/get-statuses-after-execution";

import "./tasks/deploy";

import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const chainIds = {
  goerli: 5,
  hardhat: 31337,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  ropsten: 3,
  sepolia: 11155111,
};

// Ensure that we have all the environment variables we need.
const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY;
if (!infuraApiKey) {
  throw new Error("Please set your INFURA_API_KEY in a .env file");
}

function getChainConfig(network: keyof typeof chainIds): NetworkUserConfig {
  const url: string = "https://" + network + ".infura.io/v3/" + infuraApiKey;
  return {
    accounts: {
      count: 12,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chainIds[network],
    url,
  };
}

function getBSCConfig(network: string): NetworkUserConfig {
  let config = {
    accounts: {
      count: 12,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
  };

  switch (network) {
    case "testnet":
      config.url = "https://data-seed-prebsc-1-s1.binance.org:8545";
      break;
    case "mainnet":
      config.url = "https://bsc-dataseed.binance.org";
      break;
    default:
      throw new Error("invalid config option for bsc chain");
  }

  return config;
}

const config = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
    },
    garbitrum: {
      accounts: {
        count: 20,
        mnemonic: mnemonic,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
      },
      url: 'https://arb-goerli.g.alchemy.com/v2/' + infuraApiKey,
      network_id: 421613,
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 2000,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true,     // Skip dry run before migrations? (default: false for public nets )
      gas: 6000000
    },
    goerli: getChainConfig("goerli"),
    kovan: getChainConfig("kovan"),
    rinkeby: getChainConfig("rinkeby"),
    ropsten: getChainConfig("ropsten"),
    mainnet: getChainConfig("mainnet"),
    testnet_bsc: getBSCConfig("testnet"),
    mainnet_bsc: getBSCConfig("mainnet"),
    sepolia: getChainConfig("sepolia")
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.13",
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/solidity-template/issues/31
        bytecodeHash: "none",
      },
      // Disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  abiExporter: {
    path: "./abi",
    clear: true,
    flat: false,
    only: [":Bridge$", ":ERC20Safe$"],
    pretty: false,
  },
};

export default config;
