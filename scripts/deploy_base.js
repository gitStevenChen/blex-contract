const {
  deployAll: deployAllMarket,
  initialize: initializeMarket,
} = require("./deploy/init")
const { ethers } = require("hardhat")
const { deployGlobalValid } = require("./deploy/GlobalValid")
const {
  handleTx,
  deleteAddressJson,
  deployOrConnect,
  isLocalHost,
  grantRoleIfNotGranted,
  isLocalFlow
} = require("./utils/helpers")

const { deployAll: deployAllLP } = require("./lp/deploy")
const { deployFee } = require("./fee/deployFeeAll")
const { deployReferral } = require("./referral/deploy")


const { deployOracle } = require("./oracle/deploy")
const { setMaxTimeDeviation, setPriceDataInterval, setFastPriceIsSpreadEnabled } = require("./oracle/fastPriceFeed")
const { setFastPriceEnabled, setGmxPriceFeed, setIsGmxPriceEnabled } = require("./oracle/price");
const { setPriceFeed } = require("./oracle/chainPriceFeed");

async function deployBase({ isInit = true, isFirstInit = false } = {}) {
  if (isLocalHost()) deleteAddressJson()
  const [wallet, user0, user1] = await ethers.getSigners()
  const globalValid = await deployGlobalValid(true)
  const USDC = await deployOrConnect("USDC", [
    "USDC",
    "USDC",
    "1000000000000000000",
  ])
  const lpContracts = await deployAllLP(USDC)
  let inputs = await deployAllMarket({
    deployer: wallet,
    vaultRouter: lpContracts.vaultRouter,
  })
  const feeContracts = await deployFee(inputs.marketFactory.address, true, isInit)
  await grantRoleIfNotGranted(feeContracts.feeRouter, "ROLE_CONTROLLER", lpContracts.vaultRouter.address);
  await grantRoleIfNotGranted(feeContracts.feeRouter, "ROLE_CONTROLLER", lpContracts.vaultReward.address);
  await grantRoleIfNotGranted(feeContracts.feeRouter, "ROLE_CONTROLLER", lpContracts.vault.address);


  const configs = {
    priceDuration: 300,
    maxPriceUpdateDelay: 3600,
    minBlockInterval: 0,
    maxDeviationBasisPoints: 1000
  }
  let oracleContracts
  if (isLocalHost()) {
    const fastPrice = await deployOrConnect("MockOracle")
    oracleContracts = {
      fastPrice: fastPrice,
      priceFeed: fastPrice,
    }
  } else {
    oracleContracts = await deployOracle(configs, true, isFirstInit)

    if (isFirstInit) {

      await setMaxTimeDeviation(600);
      await setPriceDataInterval(60);
      await setPriceFeed(BTC, BTCPriceFeed, 8);
      await setPriceFeed(ETH, ETHPriceFeed, 8);
      await setFastPriceIsSpreadEnabled(true);
      await setFastPriceEnabled(true);

    }
  }

  inputs = {
    ...inputs,
    ...feeContracts,
    ...lpContracts,
    ...oracleContracts,
    USDC: USDC,
    globalValid: globalValid,
  }

  if (isInit) {
    await initializeMarket(inputs)
    await lpContracts.initLP({
      ...inputs,
      name: "BLP",
      symbol: "BLP"
    })
  }
  const referralContracts = await deployReferral()


  if (isLocalHost()) {























  }


  return {
    ...inputs,
    ...referralContracts,
    feeRouter: feeContracts.feeRouter,
    rewardDistributor: lpContracts.rewardDistributor
  }
}

module.exports = {
  deployBase,
}





