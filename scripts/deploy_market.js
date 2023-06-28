const { deployPositionBook } = require("./position/positionBook")

const {
  readDeployedContract,
  handleTx,
  isLocalHost,
  grantRoleIfNotGranted,
  readContractAddresses
} = require("./utils/helpers")
const { deployMarket } = require("./deploy/addMarket")
const { deployBase } = require("./deploy_base")
const { setFeeAndRates } = require("./fee/feeRouter")
const { setPriceFeed } = require("./oracle/chainPriceFeed");
const { addPlugin: marketAddPlugin } = require("./market/market")

const addressjson = {
  "ETH": "0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08",
  "BTC": "0x6550bc2301936011c1334555e62A87705A81C12C"
}

async function runDeployMarket({ symbol = "ETH", isInit = false, results } = {}) {
  const network = process.env.HARDHAT_NETWORK || "local-dev"

  const indexToken = { address: addressjson[symbol] }
  results = {
    ...results,
    indexToken: indexToken,
    name: symbol + "/USD"
  }
  const results2 = await deployMarket(results)
  const [wallet, user0, user1] = await ethers.getSigners()
  results = { ...results, ...results2 }
  await results.setMarketLP(results)

  await setFeeAndRates(
    results.market.address,
    ["100000", "100000", "0", "1000000000000000000", "5000000000000000000"]
  )
  await handleTx(
    results.globalValid.setMaxMarketSizeLimit(
      results.market.address,
      ethers.utils.parseUnits("100000000", 18)
    ),
    "globalValid.setMaxMarketSizeLimit"
  )
  await marketAddPlugin(results.market, results.referral.address)
  await grantRoleIfNotGranted(results.referral, "ROLE_CONTROLLER", results.market.address)

  await grantRoleIfNotGranted(
    results.market,
    "ROLE_POS_KEEPER",
    results.fastPrice.address,
    "market.grant.fastPrice"
  )

  return results
}

module.exports = {
  runDeployMarket,
}
