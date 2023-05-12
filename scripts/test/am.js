
const {
    deployOrConnect,
    handleTx
} = require("./utils/helpers.js");
const {
    MockOracle,
    Market
} = require("../contract-addresses-avalancheTest.json")
const { readMarketReaderContract } = require("./market/marketReader.js")

require("dotenv").config();
const { ethers } = require("ethers");

async function runam(isOpen, symbol, isLong) {

    const rpcUrl = "https://rpc.ankr.com/avalanche_fuji";
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const signer = new ethers.Wallet(
        isOpen ? process.env.amoKey : process.env.amcKey,
        provider
    );

    const marketReader = await readMarketReaderContract()
    const res = await marketReader.getMarkets()
    let marketAddr;
    for (let index = 0; index < res.length; index++) {
        const element = res[index];
        const name = element.name
        if (name.indexOf(symbol) >= 0) {
            marketAddr = element.addr
            break
        }
    }
    if (marketAddr == null) return
    const autoOpenOrder = await deployOrConnect(
        "AutoOrderMock",
        [marketAddr, isOpen, isLong],
        symbol + "Auto" + (isOpen ? "Open" : "Close") + (isLong ? "Long" : "Short") + "OrderMock"
    );

    const res2 = await autoOpenOrder.checkExecOrder(
        0, 50
    );
    if (res2.length > 0) {
        console.log(res2);
        await handleTx(autoOpenOrder.connect(signer).performUpkeep(0, 50));
    }

}

module.exports = {
    runam
}