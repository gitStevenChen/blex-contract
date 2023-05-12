const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployMarketRouter(writeJson) {
	const router = await deployOrConnect("MarketRouter", []);

	const result = {
		MarketRouter: router.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return router;
}

async function readMarketRouterContract() {
	const router = await readDeployedContract("MarketRouter");
	return router;
}

async function initializeRouter(globalValidAddr, vaultRouterAddr) {
	const router = await readMarketRouterContract();
	await handleTx(
		router.initialize(globalValidAddr, vaultRouterAddr),
		"router.initialize"
	);
}

async function addMarket(marketAddr) {
	const router = await readMarketRouterContract();
	await handleTx(
		router.addMarket(marketAddr),
		"router.addMarket"
	);
}

async function removeMarket(marketAddr) {
	const router = await readMarketRouterContract();
	await handleTx(
		router.removeMarket(marketAddr),
		"router.removeMarket"
	);
}

module.exports = {
	deployMarketRouter,
	readMarketRouterContract,
	initializeRouter,
	addMarket,
	removeMarket,
};