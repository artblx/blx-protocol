var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic =
    "involve river kite enable pumpkin dove replace robot charge option pond coffee";

module.exports = {
    compilers: {
        solc: {
            version: "./node_modules/solc"
        }
    },
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "5777"
        },
        ropsten: {
            provider: function() {
                return new HDWalletProvider(
                    mnemonic,
                    "https://ropsten.infura.io/GMu51twdFWSbF3ov7qcf"
                );
            },
            network_id: 3,
            gas: 4000000
        }
    }
};
