const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployMarketFactory(writeJson) {
	const factory = await deployOrConnect("MarketFactory", []);

	const result = {
		MarketFactory: factory.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return factory;
}

async function readMarketFactoryContract() {
	const factory = await readDeployedContract("MarketFactory");
	return factory;
}

async function createMarket(inputs) {
	const factory = await readMarketFactoryContract();
	await handleTx(
		factory.create(inputs),
		"factory.create"
	);
}

module.exports = {
	deployMarketFactory,
	readMarketFactoryContract,
	createMarket,
};