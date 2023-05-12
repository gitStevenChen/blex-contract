const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	grantRoleIfNotGranted,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployFeeVault(writeJson) {
	const vault = await deployOrConnect("FeeVault", []);

	const result = {
		FeeVault: vault.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return vault;
}

async function readFeeVaultContract() {
	const vault = await readDeployedContract("FeeVault");
	return vault
}

async function increaseFees(marketAddr, account, fees) {
	const vault = await readFeeVaultContract();
	await handleTx(
		vault.increaseFees(marketAddr, account, fees),
		"feeVault.increaseFees"
	);
}

async function decreaseFees(marketAddr, account, fees) {
	const vault = await readFeeVaultContract();
	await handleTx(
		vault.decreaseFees(marketAddr, account, fees),
		"feeVault.decreaseFees"
	);
}

async function updateGlobalFundingRate(marketAddr, rates, timestamp) {
	const vault = await readFeeVaultContract();
	await handleTx(
		vault.updateGlobalFundingRate(
			marketAddr, 
			rates.longRate, 
			rates.shortRate, 
			rates.nextLongRate, 
			rates.nextShortRate,
			timestamp
		),
		"vault.updateGlobalFundingRate"
	);
}

async function getCumulativeFundingRates(marketAddr, isLong) {
	const vault = await readFeeVaultContract();
	const rates = await vault.cumulativeFundingRates(marketAddr, isLong);
	return rates;
}

async function getFundingRates(marketAddr, isLong) {
	const vault = await readFeeVaultContract();
	const rates = await vault.fundingRates(marketAddr, isLong);
	return rates;
}

async function getLastFundingTimes(marketAddr) {
	const vault = await readFeeVaultContract();
	const times = await vault.lastFundingTimes(marketAddr);
	return times;
}

module.exports = {
	deployFeeVault,
	readFeeVaultContract,
	increaseFees,
	decreaseFees,
	updateGlobalFundingRate,
	getCumulativeFundingRates,
	getFundingRates,
	getLastFundingTimes,
};