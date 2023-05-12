const {
  readDeployedContract,
  handleTx,
  isLocalHost,
  grantRoleIfNotGranted,
} = require("./utils/helpers");
const { deployBase } = require("./deploy_base");
const { setFeeAndRates } = require("./fee/feeRouter");
const { deployPositionBook } = require("./position/positionBook");

const { deployMarket } = require("./deploy/addMarket");
const { setPriceFeed } = require("./oracle/chainPriceFeed");

const { ETH} = require("./../commonAddress.json");

async function runDeployMarket({ symbol = "ETH", isInit = false } = {}) {
  let results = await deployBase({ isInit: isInit });
  const indexToken = { address: ETH };
  results = {
    ...results,
    indexToken: indexToken,
  };
  results = {
    ...results,
    name: symbol + "/USD",
  };
  const results2 = await deployMarket(results);
  const [wallet, user0, user1] = await ethers.getSigners();
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

  //========================
  // testcode
  //========================
  console.log("collateral token address", results.collateralToken.address);
  console.log("market reader:", results.marketReader.address);
  return results;
}

module.exports = {
  runDeployMarket,
};
