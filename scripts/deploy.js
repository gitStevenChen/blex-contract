const { runDeployMarket } = require("./deploy_market")
const { deployBase } = require("./deploy_base")
const { readMarketReaderContract } = require("./market/marketReader")
const { readMarketFactoryContract } = require("./market/marketFactory")
const { readVaultRouterContract } = require("./vault/vaultRouter")
const { handleTx, deployOrConnect } = require("./utils/helpers")

async function removeMarket(symbol) {
    const marketReader = await readMarketReaderContract()
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

            await handleTx(vaultRouter.removeMarket(addr))

            // this line will remove market address from market factory & market router
            await handleTx(marketFactory.remove(addr))
            break
        }
    }
}

async function main() {
    const usdc = await deployOrConnect("USDC", [
        "USDC",
        "USDC",
        "1000000000000000000",
    ]);
    await deployBase({ usdc: usdc, useMockOracle: true })
    await runDeployMarket({usdc:usdc, symbol: "ETH" })
    await runDeployMarket({usdc:usdc, symbol: "BTC" })
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})