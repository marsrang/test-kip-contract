//const PrivateKeyConnector = require('connect-privkey-to-provider');

const HDWalletProvider = require("truffle-hdwallet-provider-klaytn");
const NETWORK_ID = "1001";
const GASLIMIT = "5000000";

const URL = `https://api.baobab.klaytn.net:8651`;
const PRIVATE_KEY = "";

// mainnet
// const HDWalletProvider = require("truffle-hdwallet-provider-klaytn");
// const NETWORK_ID = "8217";
// const GASLIMIT = "200000000";

// const URL = `https://api.cypress.klaytn.net:8651`;
// const PRIVATE_KEY = "";

module.exports = {
  networks: {
    klaytn: {
      provider: () => new HDWalletProvider(PRIVATE_KEY, URL),
      network_id: NETWORK_ID,
      gas: GASLIMIT,
      gasPrice: null,
    },
  },

  compilers: {
    solc: {
      version: "0.5.11",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: "petersburg",
      },
    },
  },
};
