const oneGwei = web3.utils.toBN("1000000000"); // 1 GWEI
const _ = "        ";

const gasToCash = function(totalGas) {
    // web3.utils.BN.config({ DECIMAL_PLACES: 2, ROUNDING_MODE: 4 });

    if (typeof totalGas !== "object") totalGas = web3.utils.toBN(totalGas);
    let lowGwei = oneGwei.mul(web3.utils.toBN("8"));
    let highGwei = oneGwei.mul(web3.utils.toBN("20"));
    let ethPrice = web3.utils.toBN("450");

    console.log(
        _ +
            "$" +
            (
                web3.utils.fromWei(totalGas.mul(lowGwei).toString()) * ethPrice
            ).toFixed(2) +
            " @ 8 GWE, " +
            ethPrice +
            "/USD"
    );
    console.log(
        _ +
            "$" +
            (
                web3.utils.fromWei(totalGas.mul(highGwei).toString()) * ethPrice
            ).toFixed(2) +
            " @ 20 GWE, " +
            ethPrice +
            "/USD"
    );
};

module.exports = {
    _,
    gasToCash
};
