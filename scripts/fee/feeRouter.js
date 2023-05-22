const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployFeeRouter(factoryAddr, writeJson) {
	const router = await deployOrConnect("FeeRouter", [factoryAddr]);

	const result = {
		FeeRouter: router.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return router;
}

async function readFeeRouterContract() {
	const router = await readDeployedContract("FeeRouter");
	return router
}

async function initFeeRouter(feeVaultAddr, fundFeeAddr) {
	const router = await readDeployedContract("FeeRouter");
	await handleTx(
		router.initialize(feeVaultAddr, fundFeeAddr),
		"feeRouter.initialize"
	);
}

async function setFeeAndRates(market, rates) {
	const router = await readDeployedContract("FeeRouter");
	await handleTx(
		router.setFeeAndRates(market, rates),
		"feeRouter.setFeeAndRates"
	);
}

async function updateCumulativeFundingRate(marketAddr, longSize, shortSize) {
	const feeRouter = await readFeeRouterContract();
	await handleTx(
		feeRouter.updateCumulativeFundingRate(marketAddr, longSize, shortSize),
		"feeRouter.updateCumulativeFundingRate"
	);
}

async function getFeeAndRates(marketAddr, kind) {
	const feeRouter = await readFeeRouterContract();
	const feeRate = feeRouter.feeAndRates(marketAddr, kind);
	return feeRate;
}

module.exports = {
	deployFeeRouter,
	readFeeRouterContract,
	initFeeRouter,
	setFeeAndRates,
	getFeeAndRates,
	updateCumulativeFundingRate,
};
