const {
  deployAll: deployAllMarket,
  initialize: initializeMarket,
} = require("./deploy/init");
const { ethers } = require("hardhat");
const { deployGlobalValid } = require("./deploy/GlobalValid");
const {
  handleTx,
  deleteAddressJson,
  deployOrConnect,
  isLocalHost,
  grantRoleIfNotGranted,
  isLocalFlow,
} = require("./utils/helpers");

const { deployAll: deployAllLP } = require("./lp/deploy");
const { deployFee } = require("./fee/deployFeeAll");
const { deployReferral } = require("./referral/deploy");
const { deployOracle } = require("./oracle/deploy");
const { setMaxTimeDeviation } = require("./oracle/fastPriceFeed");
const { setFastPriceEnabled } = require("./oracle/price");
const { ETH } = 0xea0c41fd13852a84052b4832d87bf995c95ba8a4;
async function deployBase({ isInit = true } = {}) {
  if (isLocalHost()) deleteAddressJson();

  const [wallet, user0, user1] = await ethers.getSigners();
  const globalValid = await deployGlobalValid(true);
  const usdc = await deployOrConnect("USDC", [
    "USDC",
    "USDC",
    "1000000000000000000",
  ]);
  const lpContracts = await deployAllLP(usdc);
  let inputs = await deployAllMarket({
    deployer: wallet,
    vaultRouter: lpContracts.vaultRouter,
  });
  const feeContracts = await deployFee(
    inputs.marketFactory.address,
    true,
    isInit
  );
  await grantRoleIfNotGranted(
    feeContracts.feeRouter,
    "ROLE_CONTROLLER",
    lpContracts.vaultRouter.address
  );
  await grantRoleIfNotGranted(
    feeContracts.feeRouter,
    "ROLE_CONTROLLER",
    lpContracts.vaultReward.address
  );

  const configs = {
    priceDuration: 300,
    maxPriceUpdateDelay: 3600,
    minBlockInterval: 0,
    maxDeviationBasisPoints: 1000,
  };
  let priceFeed;
  let fastPrice;
  if (isLocalHost()) {
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
  //========================
  // 测试代码
  if (isLocalHost()) {
    // await handleTx(
    //   priceFeed.setPrice(
    //     ETH,
    //     ethers.utils.parseUnits("1956", 30)
    //   ),
    //   "priceFeed.setPrice"
    // )
    // let depositAmount = ethers.utils.parseUnits("100000000", 6)
    // await handleTx(
    //   inputs.collateralToken.approve(inputs.vaultReward.address, depositAmount),
    //   "collateralToken.approve"
    // )
    // console.log(inputs.vaultReward.address);
    // console.log(inputs.vault.address);
    // await handleTx(
    //   inputs.vaultReward.buy(
    //     inputs.vault.address,
    //     wallet.address,
    //     depositAmount,
    //     "0"
    //   ),
    //   "vault reward deposit"
    // )
  }
  //========================

  return {
    ...inputs,
    priceFeed: priceFeed,
    fastPrice: fastPrice,
  };
}

module.exports = {
  deployBase,
};

// deployBase().catch((error) => {
//     console.error(error)
//     process.exitCode = 1
// })
