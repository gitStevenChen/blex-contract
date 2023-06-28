const { readMarketContract } = require("../market/market")
const { readOrderMgrContract } = require("../market/orderMgr")

const { replacePositionAddMgr } = require("../upgrade/positionAddMgr")
const { replacePositionSubMgr } = require("../upgrade/positionSubMgr")
const { replaceOrderMgrContract } = require("../upgrade/orderMgr")
const { replaceOrderBook } = require("../upgrade/orderBook")
const { replaceFeeRouter } = require("../upgrade/feeRouter")
const { uploadToTenderfly, grantRoleIfNotGranted } = require("../utils/helpers")
const { readOrderBookContract } = require("../order/orderBook")
const { replaceCoreVault } = require("../upgrade/coreVault")
const { replaceMarketRouter } = require("../upgrade/marketRouter")

async function upgradeAll() {

    const market_ETH = await readMarketContract("ETH")
    const market_BTC = await readMarketContract("BTC")
    const [wallet] = await ethers.getSigners()






    await replaceMarketRouter({})









    /*     
    const orderMgr = await readOrderMgrContract()
    await uploadToTenderfly("OrderMgr", orderMgr) 
    */
}

upgradeAll().catch((error) => {
    console.error(error)
    process.exitCode = 1
})


