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
  // TODO 再加一个市场BTC/USD
  const marketName = "ETH/USD"
  const [deployer] = await ethers.getSigners()
  console.log("deployer: ", deployer.address)

  // -------------------------------deploy  position-----------------------------------------------//
  const marketPositionMgr = await deployOrConnect("MarketPositionMgr")
  const addressProviderContract = await deployOrConnect(
    "MarketAddressesProvider"
  )
  // -------------------------------set fee and position-----------------------------------------------//
  await handleTx(
    addressProviderContract.setMarketPositionMgr(marketPositionMgr.address)
  )
  // await uploadToTenderfly("MarketAddressesProvider", addressProviderContract)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
