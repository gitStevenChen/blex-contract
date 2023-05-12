const { 
	deployOrConnect, 
	readDeployedContract, 
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployPrice(writeJson) {
	const oracle = await deployOrConnect("Price", []);

	const result = {
		Price: oracle.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return oracle;
}

async function readOracleContract() {
	const oracle = await readDeployedContract("Price");
	return oracle
}

async function setAdjustment(token, isAdditive, adjustmentBps) {
	const oracle = await readDeployedContract("Price");

	await handleTx(
		oracle.setAdjustment(token, isAdditive, adjustmentBps),
		"oracle.setAdjustment"
	);
}

async function setFastPriceEnabled(isEnabled) {
	const oracle = await readDeployedContract("Price");

	await handleTx(
		oracle.setFastPriceEnabled(isEnabled),
		"oracle.setFastPriceEnabled"
	);
}

async function setFastPriceFeed(fastPriceAddr) {
	const oracle = await readDeployedContract("Price");
	await handleTx(
		oracle.setFastPriceFeed(fastPriceAddr),
		"oracle.setFastPriceFeed"
	);
}

async function setChainPriceFeed(chainPriceAddr) {
	const oracle = await readDeployedContract("Price");
	await handleTx(
		oracle.setChainPriceFeed(chainPriceAddr),
		"oracle.setChainPriceFeed"
	);
}

async function setOracleSpreadBasisPoints(token, spreadBasisPoints) {
	const oracle = await readDeployedContract("Price");
	await handleTx(
		oracle.setSpreadBasisPoints(token, spreadBasisPoints),
		"oracle.setSpreadBasisPoints"
	);
}

async function setSpreadThresholdBasisPoints(points) {
	const oracle = await readDeployedContract("Price");
	await handleTx(
		oracle.setSpreadThresholdBasisPoints(points),
		"oracle.setSpreadThresholdBasisPoints"
	);
}

async function setMaxStrictPriceDeviation(maxStrictPriceDeviation) {
	const oracle = await readDeployedContract("Price");
	await handleTx(
		oracle.setMaxStrictPriceDeviation(maxStrictPriceDeviation),
		"oracle.setMaxStrictPriceDeviation"
	);
}

async function setStableTokens(token, stable) {
	const oracle = await readDeployedContract("Price");
	await handleTx(
		oracle.setStableTokens(token, stable),
		"oracle.setStableTokens"
	);
}

module.exports = {
	deployPrice,
	readOracleContract,
	setAdjustment,
	setFastPriceEnabled,
	setFastPriceFeed,
	setChainPriceFeed,
	setOracleSpreadBasisPoints,
	setSpreadThresholdBasisPoints,
	setMaxStrictPriceDeviation,
	setStableTokens,
};