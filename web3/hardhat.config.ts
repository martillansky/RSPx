require("@chainlink/hardhat-chainlink");
import '@nomiclabs/hardhat-ethers';
require("@nomiclabs/hardhat-waffle")
require("hardhat-gas-reporter")
require("./tasks/block-number")
require("@nomiclabs/hardhat-etherscan")
require("dotenv").config()
require("solidity-coverage")
require("hardhat-deploy")

//import dotenv from 'dotenv';
import '@nomiclabs/hardhat-ethers';

//dotenv.config();

const { API_URL, PRIVATE_KEY } = process.env;
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

export default {
  solidity: {
    version: "0.4.26", 
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    }
  }, 
  defaultNetwork: "sepolia",
  //defaultNetwork: "hardhat",
  networks: {
    //hardhat: {},
    /* hardhat: {
      chainId: 31337,
    }, */
    localhost: {
      url: "http://localhost:8545",
      chainId: 31337,
    },
    sepolia: {
        url: API_URL,
        accounts: [`0x${PRIVATE_KEY}`]
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
    coinmarketcap: COINMARKETCAP_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
  },
}
