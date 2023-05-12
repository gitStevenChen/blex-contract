// import MarketTokenArtifact from "../artifacts/contracts/market/MarketToken.sol/Market.json";
const { deployOrConnect: deployContract, handleTx } = require("../utils/helpers");

async function deployMarketReader({
    deploy = deployContract, marketFactory
} = {}) {
    const marketReader = await deploy("MarketReader", [
        marketFactory.address
    ]);
    return marketReader
}

async function deployMarketRouter({
    deploy = deployContract,
    marketFactory
} = {}) {
    const marketReader = await deploy("MarketRouter", [marketFactory.address])
    return marketReader
}

async function deployAll({ deploy = deployContract, vaultRouter }) {
    const marketFactory = await deploy("MarketFactory")
    const marketRouter = await deployMarketRouter({
        marketFactory: marketFactory
    })

    const marketReader = await deployMarketReader({
        marketFactory: marketFactory,
        vaultRouter: vaultRouter
    })

    return {
        marketRouter: marketRouter,
        marketReader: marketReader,
        marketFactory: marketFactory,
        positionAddMgr: await deploy("PositionAddMgr"),
        positionSubMgr: await deploy("PositionSubMgr"),
        orderMgr: await deploy("OrderMgr")
    }
}

async function initialize({
    marketFactory,
    globalValid,
    vaultRouter,
    marketReader,
    marketRouter
} = {}) {
    await handleTx(marketRouter.initialize(
        globalValid.address,
        vaultRouter.address
    ), "marketRouter.init")
    await handleTx(marketReader.initialize(
        marketRouter.address,
        vaultRouter.address
    ), "marketReader.init")
}

module.exports = {
    initialize,
    deployAll
}