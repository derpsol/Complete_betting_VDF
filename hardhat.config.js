require("@nomicfoundation/hardhat-toolbox");

const ALCHEMY_API_KEY = "sdfsdfs";
const GOERLI_PRIVATE_KEY = "sdfsdfsdf";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      goerli: 'sdfsdfsfd'
    }
  }

};
