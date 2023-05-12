const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	grantRoleIfNotGranted,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployFundFee(feeVaultAddr, writeJson) {
	const fundFee = await deployOrConnect("FundFee", [feeVaultAddr]);

	const result = {
		FundFee: fundFee.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return fundFee;
}

async function readFundFeeContract() {
	const fee = await readDeployedContract("FundFee");
	return fee
}

async function setMinRateLimit(limit) {
	const fundFee = await readDeployedContract("FundFee");
	await handleTx(
		fundFee.setMinRateLimit(limit),
		"fundFee.setMinRateLimit"
	);
}

async function setFundingInterval(markets, intervals) {
	const fundFee = await readDeployedContract("FundFee");
	await handleTx(
		fundFee.setFundingInterval(markets, intervals),
		"fundFee.setFundingInterval"
	);
}

async function addSkipTime(startTime, endTime) {
	const fundFee = await readDeployedContract("FundFee");
	await handleTx(
		fundFee.addSkipTime(startTime, endTime),
		"fundFee.addSkipTime"
	);
}

async function getFundingRate(marketAddr, longSize, shortSize, isLong) {
	const fundFee = await readFundFeeContract();
	const rate = await fundFee.getFundingRate(marketAddr, longSize, shortSize, isLong);
	return rate;
}

async function getFundingFee(marketAddr, size, entryFundingRate, isLong) {
	const fundFee = await readFundFeeContract();
	const fee = await fundFee.getFundingFee(marketAddr, size, entryFundingRate, isLong);
	return fee;
}

async function updateCumulativeFundingRate(marketAddr, longSize, shortSize) {
	const fundFee = await readFundFeeContract();
	await handleTx(
		fundFee.updateCumulativeFundingRate(marketAddr, longSize, shortSize),
		"fundFee.updateCumulativeFundingRate"
	);
}

async function getMinRateLimit() {
	const fundFee = await readFundFeeContract();
	const limit = await fundFee.minRateLimit();
	return limit;
}

module.exports = {
	deployFundFee,
	readFundFeeContract,
	setMinRateLimit,
	setFundingInterval,
	addSkipTime,
	getFundingRate,
	getFundingFee,
	updateCumulativeFundingRate,
	getMinRateLimit,
};