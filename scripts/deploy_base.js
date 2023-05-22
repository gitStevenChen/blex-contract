const {
  deployAll: deployAllMarket,
  initialize: initializeMarket,
} = require("./deploy/init");
const { ethers } = require("hardhat");
const { deployGlobalValid } = require("./deploy/GlobalValid");
const {
  deleteAddressJson,
  deployOrConnect,
  isLocalHost,
  grantRoleIfNotGranted,
} = require("./utils/helpers");

const { deployAll: deployAllLP } = require("./lp/deploy");
const { deployFee } = require("./fee/deployFeeAll");
const { deployReferral } = require("./referral/deploy");
const { deployOracle } = require("./oracle/deploy");
const { setMaxTimeDeviation } = require("./oracle/fastPriceFeed");
const { setFastPriceEnabled } = require("./oracle/price");
async function deployBase({ isInit = true, usdc, useMockOracle } = {}) {
  if (isLocalHost()) deleteAddressJson();

  const [wallet, user0, user1] = await ethers.getSigners();
  const globalValid = await deployGlobalValid(true);
  const lpContracts = await deployAllLP(usdc);
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
    maxDeviationBasisPoints: 1000,
  };
  let priceFeed;
  let fastPrice;
  if (useMockOracle) {
    priceFeed = await deployOrConnect("MockOracle");
    fastPrice = priceFeed;
  } else {
    priceFeed = (await deployOracle(configs, true)).price;
    fastPrice = (await deployOracle(configs, true)).fastPrice;
    await setMaxTimeDeviation(600);
    await setFastPriceEnabled(true);
  }

  inputs = {
    ...inputs,
    ...feeContracts,
    ...lpContracts,
    globalValid: globalValid,
  };

  if (isInit) {
    await initializeMarket(inputs);
    await lpContracts.initLP(inputs);
  }
  await deployReferral();
  return {
    ...inputs,
    feeRouter: feeContracts.feeRouter,
    rewardDistributor: lpContracts.rewardDistributor,
    priceFeed: priceFeed,
    fastPrice: fastPrice,
  };
}

module.exports = {
  deployBase,
};