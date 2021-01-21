require('@nomiclabs/hardhat-waffle');
require("@nomiclabs/hardhat-etherscan");
require('hardhat-gas-reporter');

const config = require('./.config.json');

const mainnetAccounts = [
  config.accounts.mainnet.privateKey
];
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${config.alchemy.mainnet.apiKey}`,
      }
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${config.alchemy.mainnet.apiKey}`,
      accounts: mainnetAccounts,
      gasMultiplier: 1.1,
      gasPrice: 30000000000, // 30 gwei
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.6.8',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: '0.5.17',
      }
    ]
  },
  mocha: {
    timeout: 5*60*1000 // 5 minutes
  },
  gasReporter: {
    enabled: (process.env.REPORT_GAS) ? true : false,
    currency: 'USD',
    gasPrice: 42,
    coinmarketcap: `${config.coinmarketcap.apiKey}`,
  },
  etherscan: {
    apiKey: `${config.etherscan.apiKey}`
  },
};

