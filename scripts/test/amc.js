// const ethers = require("ethers");
const { ethers } = require("hardhat");
const { deployOrConnect2, handleTx, grantRoleIfNotGranted } = require("./utils/helpers.js");
const { MockOracle, Market } = require("../contract-addresses-avalancheTest.json")
const { readMarketReaderContract } = require("./market/marketReader.js")
require("dotenv").config();
const autoOrderCache = {};

async function getAutoOpenOrder(symbol, marketAddr, isOpen, isLong) {
    const key = `${symbol}-${isOpen}-${isLong}`;
    if (!autoOrderCache[key]) {
        autoOrderCache[key] = await deployOrConnect2(
            symbol,
            "AutoOrderMock",
            [marketAddr, isOpen, isLong],
            "Auto" + (isOpen ? "Open" : "Close") + (isLong ? "Long" : "Short") + "OrderMock",
            // symbol + "Auto" + (isOpen ? "Open" : "Close") + (isLong ? "Long" : "Short") + "OrderMock",
            null,
            false
        );

        const contractFactory = await ethers.getContractFactory("Market")
        const marketCon = await contractFactory.attach(marketAddr)
        await grantRoleIfNotGranted(
            marketCon,
            "ROLE_POS_KEEPER",
            autoOrderCache[key].address,
            "grant auto order"
        )
    }
    return autoOrderCache[key];
}

let marketReader = null
async function runam(isOpen, symbol, isLong, signer) {
    if (marketReader == null) marketReader = await readMarketReaderContract();
    const marketAddr = await findMarketAddress(symbol, marketReader);
    if (marketAddr == null) return;
    const autoOpenOrder = await getAutoOpenOrder(symbol, marketAddr, isOpen, isLong);
    const res = await autoOpenOrder.checkExecOrder(0, 50);
    if (res.length > 0) {
        console.log(res);
        await handleTx(autoOpenOrder.connect(signer).performUpkeep(0, 50));
    }
}

async function findMarketAddress(symbol, marketReader) {
    const markets = await marketReader.getMarkets();
    for (const market of markets) {
        if (market.name.indexOf(symbol) >= 0) {
            return market.addr;
        }
    }
    return null;
}

async function executeRunamOperations(signer) {
    const operations = [
        { isOpen: true, symbol: "BTC", isLong: true },
        { isOpen: true, symbol: "BTC", isLong: false },
        { isOpen: false, symbol: "BTC", isLong: true },
        { isOpen: false, symbol: "BTC", isLong: false },
        { isOpen: true, symbol: "ETH", isLong: true },
        { isOpen: true, symbol: "ETH", isLong: false },
        { isOpen: false, symbol: "ETH", isLong: true },
        { isOpen: false, symbol: "ETH", isLong: false },
    ];

    for (const operation of operations) {
        await runam(operation.isOpen, operation.symbol, operation.isLong, signer);
    }

}

async function main() {
    try {
        const rpcUrl = "https://rpc.ankr.com/avalanche_fuji";
        const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
        let signer = new ethers.Wallet(
            process.env.amoKey,
            provider
        );
        while (1) {
            await executeRunamOperations(signer);
            await new Promise((resolve) => setTimeout(resolve, 1000));
            // break
        }
    } catch (error) {
        console.error("Error in main loop: ", error);
    }
}


main().catch((error) => {
    console.error("Error in main function: ", error);
    process.exitCode = 1;
});
