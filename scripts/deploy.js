const { runDeployMarket } = require("./deploy_market")
const { deployBase } = require("./deploy_base")
const { readMarketReaderContract } = require("./market/marketReader")
const { readMarketRouterContract } = require("./market/marketRouter")
const { readMarketFactoryContract } = require("./market/marketFactory")
const { readVaultRouterContract } = require("./vault/vaultRouter")
const { handleTx, deployOrConnect } = require("./utils/helpers")

async function removeMarket(symbol) {
    const marketReader = await readMarketReaderContract()
    const marketRouter = await readMarketRouterContract()
    const vaultRouter = await readVaultRouterContract()
    const marketFactory = await readMarketFactoryContract()
    const res = await marketReader.getMarkets()
    for (let index = 0; index < res.length; index++) {
        const element = res[index];
        const addr = element.addr
        console.log(element.name);
        console.log(symbol);
        console.log(element.name.indexOf(symbol) >= 0);
        if (element.name.indexOf(symbol) >= 0) {
            // await handleTx(marketRouter.removeMarket(addr))
            await handleTx(vaultRouter.removeMarket(addr))
            await handleTx(marketFactory.remove(addr))
            // console.log(addr);
            // console.log(marketRouter.address);
            // console.log(vaultRouter.address);
            break
        }
    }
}

async function aaa(addr) {
    const marketRouter = await readMarketRouterContract()
    const vaultRouter = await readVaultRouterContract()
    const coreVault = await deployOrConnect("CoreVault")
    await handleTx(marketRouter.addMarket(addr), "mrtouer.addmarket")
    await handleTx(vaultRouter.setMarket(addr, coreVault.address), "vaultRouter.addmarket")
}

async function removeMarket(symbol) {
    const marketReader = await readMarketReaderContract()
    const marketRouter = await readMarketRouterContract()
    const vaultRouter = await readVaultRouterContract()
    const marketFactory = await readMarketFactoryContract()
    const res = await marketReader.getMarkets()
    for (let index = 0; index < res.length; index++) {
        const element = res[index];
        const addr = element.addr
        console.log(element.name);
        console.log(symbol);
        console.log(element.name.indexOf(symbol) >= 0);
        if (element.name.indexOf(symbol) >= 0) {
            // await handleTx(marketRouter.removeMarket(addr))
            // await handleTx(vaultRouter.removeMarket(addr))
            await handleTx(marketFactory.remove(addr))
            // console.log(addr);
            // console.log(marketRouter.address);
            // console.log(vaultRouter.address);
            break
        }
    }
}
async function main() {
    await deployBase({})
    // await aaa("0xca8C5bD030bAEA4D68e1747D1123ab7e94AF261c")
    // await aaa("0x01704854321F1043AaAC95a3f26E5AE529C61A1E")
    await runDeployMarket({ symbol: "ETH" })
    await runDeployMarket({ symbol: "BTC" })
    // await removeMarket("ETH")
    // await removeMarket("BTC")
    // await removeMarket("ETH")
    // await removeMarket("BTC")
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})