const { deployOrConnect, deployContract, readDeployedContract, handleTx } = require("../utils/helpers");

async function deployFeeRouter() {
	const router = await deployContract("MockFeeRouter", []);
	return router;
}

async function readFeeRouterContract() {
    const router = await readDeployedContract("MockFeeRouter");
    return router
}

async function setRouterFundFee(feeAmount) {
	const router = await deployOrConnect("MockFeeRouter", []);
	await handleTx(
		router.setFundFee(feeAmount),
		"feeRouter.setFundFee"
	);
}

async function setCumulativeFundingRate(feeRouter, marketAddr, isLong, rate) {
  await handleTx(
    feeRouter.setCumulativeFundingRates(marketAddr, isLong, rate),
    "feeRouter.setCumulativeFundingRates"
  );
}

module.exports = {
	deployFeeRouter,
	readFeeRouterContract,
	setRouterFundFee,
	setCumulativeFundingRate,
};