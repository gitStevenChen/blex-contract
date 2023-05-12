const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployMarketReader(factoryAddr, writeJson) {
	const reader = await deployOrConnect("MarketReader", [factoryAddr]);

	const result = {
		MarketReader: reader.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return reader;
}

async function readMarketReaderContract() {
	const reader = await readDeployedContract("MarketReader");
	return reader;
}

async function initializeReader(marketRouterAddr, vaultRouterAddr) {
	const reader = await readMarketReaderContract();
	await handleTx(
		reader.initialize(marketRouterAddr, vaultRouterAddr),
		"reader.initialize"
	);
}

module.exports = {
	deployMarketReader,
	readMarketReaderContract,
	initializeReader,
};