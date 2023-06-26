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
const { setLiquidateFeeRate } = require("./fee/feeRouter");
const { setMaxMarketSizeLimit } = require("./position/positionValid");

async function main() {

  const marketName = "ETH/USD"
  const [deployer] = await ethers.getSigners()
  console.log("deployer: ", deployer.address)

  let marketValid = await deployOrConnect("MarketValid")

  /**uint256 _minSlippage,
    uint256 _maxSlippage,
    uint256 _minLeverage,
    uint256 _maxLeverage,
    uint256 _maxTradeAmount,
    uint256 _minPay,
    uint256 _minCollateral,
    bool _allowOpen,
    bool _allowClose,
    uint256 _tokenDigits */
  const minSlippage = "1"
  const maxSlippage = "500"
  const minLeverage = "2"
  const maxLeverage = "200"
  const maxTradeAmount = "100000"
  const minPay = "10"
  const minCollateral = "5"
  const allowOpen = true
  const allowClose = true

  const COLLATERAL_TOKEN_DECIMAL = 18
  await handleTx(marketValid.setConf(
    minSlippage,
    maxSlippage,
    minLeverage,
    maxLeverage,
    maxTradeAmount,
    minPay,
    minCollateral,
    allowOpen,
    allowClose,
    COLLATERAL_TOKEN_DECIMAL + "",
  ))
  const addressProviderContract = await deployOrConnect(
    "MarketAddressesProvider"
  )
  const market = await deployOrConnect("Market", [])

  await handleTx(
    addressProviderContract.setMarketValid(market.address, marketValid.address),
    "setMarketValid"
  )

}



main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
