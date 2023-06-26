
const {
    deployOrConnect: deployContract,
    handleTx,
    deployUpgradeable,
    writeContractAddresses,
    getContractAt
} = require("../utils/helpers");

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
    marketFactory,
    writeJson = true
} = {}) {
    const { implementation, proxy } = await deployUpgradeable("MarketRouter", "MarketRouter")
    const result = {
        MarketRouter: proxy.address,
        ["MarketRouterImpl"]: implementation.address,
    };
    const newContract = await getContractAt("MarketRouter", proxy.address)
    if (writeJson) writeContractAddresses(result);
    return newContract
}

async function initializeMarketRouter({
    marketFactory,
    globalValid,
    vaultRouter,
    marketReader,
    marketRouter
} = {}) {
    await handleTx(marketRouter.initialize(
        marketFactory.address,
        globalValid.address,
        vaultRouter.address
    ), "marketRouter.init")
}

async function initializeMarketReader({
    marketFactory,
    globalValid,
    vaultRouter,
    marketReader,
    marketRouter
} = {}) {
    await handleTx(marketReader.initialize(
        marketRouter.address,
        vaultRouter.address
    ), "marketReader.init")
}

async function initialize({
    marketFactory,
    globalValid,
    vaultRouter,
    marketReader,
    marketRouter
} = {}) {

    await initializeMarketRouter({
        marketFactory,
        globalValid,
        vaultRouter,
        marketReader,
        marketRouter
    })

    await initializeMarketReader({
        marketFactory,
        globalValid,
        vaultRouter,
        marketReader,
        marketRouter
    })

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
        orderMgr: await deploy("OrderMgr"),
    }
}

module.exports = {
    initialize,
    deployAll
}