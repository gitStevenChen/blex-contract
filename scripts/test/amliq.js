const {
    deployOrConnect2,
    handleTx,
    grantRoleIfNotGranted
} = require("./utils/helpers.js");
const { readMarketReaderContract } = require("./market/marketReader.js")

const {
    MockOracle
} = require("../contract-addresses-avalancheTest.json");
const { ethers } = require("hardhat");
const autoOrderCache = {};

async function getAutoOpenOrder(symbol, marketAddr, isLong) {
    const key = `${symbol}-${isLong}`;
    if (!autoOrderCache[key]) {
        autoOrderCache[key] = await deployOrConnect2(
            symbol,
            "AutoLiquidateMock",
            [marketAddr, isLong],
            `Auto${isLong ? "Long" : "Short"}LiqMock`
        );

        const contractFactory = await ethers.getContractFactory("Market")
        const marketCon = await contractFactory.attach(marketAddr)
        await grantRoleIfNotGranted(
            marketCon,
            "ROLE_POS_KEEPER",
            autoOrderCache[key].address,
            "grant auto liq"
        )
    }
    return autoOrderCache[key];
}

async function runliq(symbol, isLong, signer) {
    const marketReader = await readMarketReaderContract();
    const res = await marketReader.getMarkets();
    const element = res.find((element) => element.name.includes(symbol));
    const marketAddr = element && element.addr;

    if (!marketAddr) return;
    const autoLiquidate = await getAutoOpenOrder(symbol, marketAddr, isLong);
    const res2 = await autoLiquidate.checkUpkeep(0, 50);

    if (res2.length > 0) {
        await handleTx(
            autoLiquidate.connect(signer).performUpkeep(0, 50),
            "AutoLiquidate.performUpkeep"
        );
    }
}
async function main() {
    const rpcUrl = "https://rpc.ankr.com/avalanche_fuji";
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const signer = new ethers.Wallet(process.env.amqKey, provider);

    while (1) {
        await runliq("ETH", true, signer);
        await runliq("ETH", false, signer);
        await runliq("BTC", true, signer);
        await runliq("BTC", false, signer);
        await new Promise((resolve) => setTimeout(resolve, 1000));

    }
}
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
}) 
