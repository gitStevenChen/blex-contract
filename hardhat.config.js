/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-waffle");

try {
  if (process.env.UseTenderly == "True") {
    require("@tenderly/hardhat-tenderly");
  }
} catch (error) {}

require("dotenv").config();

const LOCAL_URL = "http://127.0.0.1:8545/";

module.exports = {
  networks: {
    localhost: {
      timeout: 120000,
      url: LOCAL_URL,
      gas: 8000000,
      gasPrice: 8000000000,
    },
    hardhat: {
      hostname: "0.0.0.0",
      gas: 3000000,
      allowUnlimitedContractSize: true,
    },
    avalancheTest: {
      url: "https://rpc.ankr.com/avalanche_fuji",
      chainId: 43113,
      accounts: [process.env.PRIVATE_KEY],
      gas: 8000000,
      gasPrice: 25000000000,
    },
    ArbitrumGoerli: {
      url: "https://goerli-rollup.arbitrum.io/rpc",
      chainId: 421613,
      gas: 8000000,
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 25000000000,
    },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1,
      },
    },
  },
};
