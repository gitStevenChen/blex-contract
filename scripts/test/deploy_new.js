const {
  deployOrConnect,
  readDeployedContract,
  handleTx,
  grantRoleIfNotGranted,
  isLocalFlow,
} = require("../utils/helpers")

const { createMarket } = require("./market/deployAll.js");
const { deployFee } = require("../fee/deployFeeAll.js");
const { deployAll: deployAllLP } = require("../lp/deploy.js")
const { deployAll: deployReferral } = require("../referral/deploy.js");
const { setFeeAndRates } = require("../fee/feeRouter")
const { setMaxMarketSizeLimit } = require("../market/globalValid.js");

/**
 * @param {object {
 * }} configs
 * @param {bool} writeJson
 */

async function deploy() {
    const [wallet] = await ethers.getSigners()

    const amount = ethers.utils.parseUnits("10000000000000000000000", 6)
    const indexToken = "0xEa0c41Fd13852a84052b4832d87BF995C95Ba8A4";
    const usdc = await deployOrConnect("USDC", ["USDC", "USDC", amount]);
    const name = 'ETH/USD';

    const lpContracts = await deployAllLP(usdc);
    const priceFeed = await deployOrConnect("MockOracle");
    const feeContracts = await deployFee(true);
    await deployReferral();

    const contracts = {
  		oracle: priceFeed.address,
  		indexToken: indexToken,
  		feeRouter: feeContracts.feeRouter.address,
  		vaultRouter: lpContracts.vaultRouter.address,
  		collateralToken: usdc.address,
    }
    const configs = {
      minSlippage: 1,
      maxSlippage: 500,
      minLeverage: 2,
      maxLeverage: 200,
      maxTradeAmount: 100000,
      minPay: 10,
      minCollateral: 5,
      allowOpen: true,
      allowClose: true,
      tokenDigits: 18
    }

    const results = await createMarket(name, contracts, configs, true);

    await lpContracts.init(
      lpContracts.vault,
      lpContracts.vaultRouter,
      lpContracts.vaultReward,
      feeContracts.feeRouter
    )
    await lpContracts.setMarket(results.market.address, lpContracts.vault.address)

    await setFeeAndRates(
      results.market.address,
      [0, 1, 3, 4],
      ["100000", "100000", "1000000000000000000", "5000000000000000000"]
    )

    await setMaxMarketSizeLimit(
      results.market.address, 
      ethers.utils.parseUnits("100000000", 18)
    );

  //========================
  // testcode
  //========================

  if (isLocalFlow) {
    await handleTx(
      priceFeed.setPrice(indexToken, ethers.utils.parseUnits("1700", 30)),
      "priceFeed.setPrice"
    )
  }
  return results
}

deploy().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
