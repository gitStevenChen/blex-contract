const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployFastPriceFeed(
	priceDuration,
	maxPriceUpdateDelay,
	minBlockInterval,
	maxDeviationBasisPoints,
	writeJson
) {
	const fastPrice = await deployOrConnect("FastPriceFeed", [
		priceDuration,
		maxPriceUpdateDelay,
		minBlockInterval,
		maxDeviationBasisPoints
	]);

	const result = {
		FastPriceFeed: fastPrice.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return fastPrice;
}

async function readFastPriceContract() {
	const fastPrice = await readDeployedContract("FastPriceFeed");
	return fastPrice
}

async function setFastPricePriceFeed(chainPriceAddr) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setPriceFeed(chainPriceAddr),
		"fastPrice.setPriceFeed"
	);
}

async function setMaxTimeDeviation(deviation) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setMaxTimeDeviation(deviation),
		"fastPrice.setMaxTimeDeviation"
	);
}

async function setPriceDuration(duration) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setPriceDuration(duration),
		"fastPrice.setPriceDuration"
	);
}

async function setMaxPriceUpdateDelay(delay) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setMaxPriceUpdateDelay(delay),
		"fastPrice.setMaxPriceUpdateDelay"
	);
}

async function setSpreadBasisPointsIfInactive(point) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setSpreadBasisPointsIfInactive(point),
		"fastPrice.setSpreadBasisPointsIfInactive"
	);
}

async function setSpreadBasisPointsIfChainError(point) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setSpreadBasisPointsIfChainError(point),
		"fastPrice.setSpreadBasisPointsIfChainError"
	);
}

async function setMinBlockInterval(interval) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setMinBlockInterval(interval),
		"fastPrice.setMinBlockInterval"
	);
}

async function setFastPriceIsSpreadEnabled(enabled) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setIsSpreadEnabled(enabled),
		"fastPrice.setIsSpreadEnabled"
	);
}

async function setLastUpdatedAt(lastUpdatedAt) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setLastUpdatedAt(lastUpdatedAt),
		"fastPrice.setLastUpdatedAt"
	);
}

async function setMaxDeviationBasisPoints(maxDeviationBasisPoints) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setMaxDeviationBasisPoints(maxDeviationBasisPoints),
		"fastPrice.setMaxDeviationBasisPoints"
	);
}

async function setMaxCumulativeDeltaDiffs(tokens, maxCumulativeDeltaDiffs) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setMaxCumulativeDeltaDiffs(tokens, maxCumulativeDeltaDiffs),
		"fastPrice.setMaxCumulativeDeltaDiffs"
	);
}

async function setPriceDataInterval(priceDataInterval) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setPriceDataInterval(priceDataInterval),
		"fastPrice.setPriceDataInterval"
	);
}


async function setFastPriceTokens(tokens, tokenPrecisions) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setTokens(tokens, tokenPrecisions),
		"fastPrice.setTokens"
	);
}


async function setFastPricePrices(tokens, prices, timestamp) {
	const fastPrice = await readDeployedContract("FastPriceFeed");

	await handleTx(
		fastPrice.setPrices(tokens, prices, timestamp),
		"fastPrice.setPrices"
	);
}

module.exports = {
	deployFastPriceFeed,
	readFastPriceContract,
	setFastPricePriceFeed,
	setMaxTimeDeviation,
	setPriceDuration,
	setMaxPriceUpdateDelay,
	setSpreadBasisPointsIfInactive,
	setSpreadBasisPointsIfChainError,
	setMinBlockInterval,
	setFastPriceIsSpreadEnabled,
	setLastUpdatedAt,
	setMaxDeviationBasisPoints,
	setMaxCumulativeDeltaDiffs,
	setPriceDataInterval,
	setFastPriceTokens,
	setFastPricePrices,
};