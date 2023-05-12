const {
  deployOrConnect,
  handleTx,
  copyAbis2,
  copyAddressJson,
  copyLocalDevAddressJson,
  isLocalFlow,
} = require("../utils/helpers_cp")
const { utils } = require("ethers")
const {
  initOracle,
  setFeePosition,
  setFeeRate,
  setPosition,
  initFee,
  grantRoleIfNotGranted,
} = require("../../test/common.js")
const { BigNumber: BN } = require("ethers")
const { ethers } = require("hardhat")
const { mintAddr } = require("../../.mint.json")
const { setLiquidateFeeRate } = require("../fee/feeRouter");
const { setMaxMarketSizeLimit } = require("./position/positionValid");

async function main() {
  const market = await deployOrConnect("Market", [])
  const marketImpl = await deployOrConnect("MarketImpl", [])

  //await uploadToTenderfly("MarketImpl", marketImpl)

  if ((await market.marketImpl()) != marketImpl.address) {
    await handleTx(
      market.setMarketImpl(marketImpl.address)
    )
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
