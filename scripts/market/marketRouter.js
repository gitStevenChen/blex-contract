const {
	deployOrConnect,
	deployContract,
	readDeployedContract,
	handleTx,
	readContractAddresses,
	writeContractAddresses,
	getContractAt,
	deployUpgradeable
} = require("../utils/helpers");

async function deployMarketRouter({
	deploy = deployContract,
	marketFactory,
	writeJson = true
} = {}) {
	const { implementation, proxy } = await deployUpgradeable("MarketRouter", "MarketRouter")
	const result = {
		MarketRouter: proxy.address,
		["MarketRouterImpl"]: implementation.address,
	};
	const newContract = await getContractAt("MarketRouter", proxy.address)
	if (writeJson) writeContractAddresses(result);
	return newContract
}

async function readMarketRouterContract() {
	let existingObj = readContractAddresses()
	const newContract = await getContractAt(
		"MarketRouter",
		existingObj['MarketRouter']
	)
	return newContract
}

async function setIsEnableMarketConvertToOrder(_enable) {
	const contract = await readMarketRouterContract()
	await handleTx(
		contract.setIsEnableMarketConvertToOrder(_enable),
		"setIsEnableMarketConvertToOrder"
	)
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
	setIsEnableMarketConvertToOrder,
	readMarketRouterContract,
	initializeRouter,
	addMarket,
	removeMarket,
};