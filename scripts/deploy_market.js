const {
  handleTx,
  deployOrConnect,
} = require("./utils/helpers");
const { deployBase } = require("./deploy_base");
const { setFeeAndRates } = require("./fee/feeRouter");
const { deployMarket } = require("./deploy/addMarket");
const commonAddresses = require("./../commonAddress.json");

async function runDeployMarket({usdc, symbol, isInit = false } = {}) {
  let results = await deployBase({ isInit: isInit, usdc });
  const indexToken = { address: commonAddresses[symbol] };
  results = {
    ...results,
    indexToken: indexToken,
  };
  results = {
    ...results,
    name: symbol + "/USD",
  };
  const results2 = await deployMarket(results);
  results = { ...results, ...results2 };
  await results.setMarketLP(results);

  await setFeeAndRates(results.market.address, [
    "100000",
    "100000",
    "0",
    "1000000000000000000",
    "5000000000000000000",
  ]);
  await handleTx(
    results.globalValid.setMaxMarketSizeLimit(
      results.market.address,
      ethers.utils.parseUnits("100000000", 18)
    ),
    "globalValid.setMaxMarketSizeLimit"
  );
  return results;
}

module.exports = {
  runDeployMarket,
};
