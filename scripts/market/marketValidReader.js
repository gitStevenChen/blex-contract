const {
	deployOrConnect,
	deployContract,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployMarketValidReader(marketValidAddr, writeJson) {
	const reader = await deployContract("MarketValidReader", [marketValidAddr]);

	const result = {
		MarketValidReader: reader.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return reader;
}

async function readMarketValidReaderContract() {
	const reader = await readDeployedContract("MarketValidReader");
	return reader;
}

module.exports = {
	deployMarketValidReader,
	readMarketValidReaderContract,
};