require("@nomicfoundation/hardhat-toolbox");

const ALCHEMY_API_KEY = "QARk6wvaaHlcADJr55SrUhFmACjgP0lZ";
const GOERLI_PRIVATE_KEY = "a6e04993f1734ef427447820a8067bd27446b99d23b5639fc815189c79a6ba43";

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
      goerli: 'DEHCB9QGHRA42MIX935Z9SQI9DRD3FYYDG'
    }
  }

};
