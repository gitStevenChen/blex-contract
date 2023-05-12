const {
  deployOrConnect,
  handleTx,
  copyAbis2,
  copyAddressJson,
  copyLocalDevAddressJson,
  isLocalFlow,
} = require("./helpers")
const { utils } = require("ethers")
const {
  initOracle,
  setFeePosition,
  setFeeRate,
  setPosition,
  initFee,
  grantRoleIfNotGranted,
} = require("../test/common.js")
const { BigNumber: BN } = require("ethers")
const { ethers } = require("hardhat")
const { mintAddr } = require("../.mint.json")
const { setLiquidateFeeRate } = require("./fee/feeRouter")
const { setMaxMarketSizeLimit } = require("./position/positionValid")

async function main() {
  // TODO 再加一个市场BTC/USD

  const [deployer] = await ethers.getSigners()
  console.log("deployer: ", deployer.address)
  // -------------------------------deploy  position-----------------------------------------------//
  const orderBookLong = await deployOrConnect(
    "OrderBook",
    [true],
    "OrderBookLong"
  )
  const orderBookShort = await deployOrConnect(
    "OrderBook",
    [false],
    "OrderBookShort"
  )
  const OrderStoreOpenLong = await deployOrConnect(
    "OrderStore",
    [true],
    "OpenStoreLong"
  )
  const OrderStoreCloseLong = await deployOrConnect(
    "OrderStore",
    [true],
    "CloseStoreLong"
  )
  const OrderStoreOpenShort = await deployOrConnect(
    "OrderStore",
    [false],
    "OpenStoreShort"
  )
  const OrderStoreCloseShort = await deployOrConnect(
    "OrderStore",
    [false],
    "CloseStoreShort"
  )
  const market = await deployOrConnect("Market", [])
  // =============================================
  //
  // =============================================
  // 给market授权
  await grantRoleIfNotGranted(
    orderBookLong,
    "ROLE_MARKET",
    market,
    "_orderBookL.grantRole"
  )
  await grantRoleIfNotGranted(
    orderBookShort,
    "ROLE_MARKET",
    market,
    "_orderBookS.grantRole"
  )
  // 设置ob权限
  await handleTx(
    OrderStoreOpenLong.setOrderBook(orderBookLong.address),
    "_openStoreLong"
  )

  await handleTx(
    OrderStoreCloseLong.setOrderBook(orderBookLong.address),
    "_closeStoreLong"
  )

  await handleTx(
    OrderStoreOpenShort.setOrderBook(orderBookShort.address),
    "_openStoreShort"
  )

  await handleTx(
    OrderStoreCloseShort.setOrderBook(orderBookShort.address),
    "_closeStoreShort"
  )

  // 设置ob地址
  await handleTx(orderBookLong.initialize(
    OrderStoreOpenLong.address, OrderStoreCloseLong.address
  ))
  await handleTx(orderBookShort.initialize(
    OrderStoreOpenShort.address, OrderStoreCloseShort.address
  ));
  const marketRouter = "0x5FbDB2315678afecb367f032d93F642f64180aa3" // 暂时不管她
  await handleTx(market.initialize(
    (await deployOrConnect("PositionBook", [])).address,
    orderBookLong.address,
    orderBookShort.address,
    (await deployOrConnect("MarketAddressesProvider", [])).address,
    (await deployOrConnect("LPToken", [], "ETH")).address,
    (await deployOrConnect("FeeRouter", [])).address,
    (await deployOrConnect("FeeVault", [])).address,
    marketRouter,
    (await deployOrConnect("CoreVault", [])).address,
    (await deployOrConnect("ERC4626Router", [], "VaultRouter")).address,
    (await deployOrConnect("USDC", [])).address//collateral token
  ));

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
