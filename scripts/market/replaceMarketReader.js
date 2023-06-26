const { deployMarketReader, initializeReader } = require("./marketReader.js")
const { readMarketFactoryContract } = require("./marketFactory.js")
const { readMarketRouterContract } = require("./marketRouter.js")
const { readVaultRouterContract } = require("../vault/vaultRouter.js")

async function replaceMarketReader() {


    const marketRouter = await readMarketRouterContract()
    const vaultRouter = await readVaultRouterContract()
    await initializeReader(marketRouter.address, vaultRouter.address)
}

replaceMarketReader().catch((error) => {
    console.error(error)
    process.exitCode = 1
})