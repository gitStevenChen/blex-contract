const { deployOrConnect, deployContract, readDeployedContract, handleTx } = require("../utils/helpers");

async function deployFeeStore() {
	const feeStore = await deployContract("MockFeeStore", []);
	return feeStore;
}

async function setCumulativeFundingRate(feeStore, marketAddr, isLong, rate) {
  await handleTx(
    feeStore.setCumulativeFundingRates(marketAddr, isLong, rate),
    "feeStore.setCumulativeFundingRates"
  );
}

module.exports = {
	deployFeeStore,
	setCumulativeFundingRate,
};