
const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployMarket(factoryAddr, writeJson) {
	const market = await deployOrConnect("Market", [factoryAddr]);

	const result = {
		Market: market.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return market;
}

async function readMarketContract() {
	const market = await readDeployedContract("Market");
	return market;
}

async function initialize(name, initAddrs) {
	const market = await readMarketContract();
	await handleTx(
		market.initialize(initAddrs, name),
		"market.initialize"
	);
}

async function addPlugin(pluginAddr) {
	const market = await readMarketContract();
	await handleTx(
		market.addPlugin(pluginAddr),
		"market.addPlugin"
	);
}

async function setOrderBooks(orderBookLongAddr, orderBookShortAddr) {
	const market = await readMarketContract();
	await handleTx(
		market.setOrderBooks(orderBookLongAddr, orderBookShortAddr),
		"market.setOrderBooks"
	);
}

async function setPositionBook(positionBookAddr) {
	const market = await readMarketContract();
	await handleTx(
		market.setPositionBook(positionBookAddr),
		"market.setPositionBook"
	);
}

async function setMarketValid(marketValidAddr) {
	const market = await readMarketContract();
	await handleTx(
		market.setMarketValid(marketValidAddr),
		"market.setMarketValid"
	);
}

async function setPositionMgr(mgrAddr, isAdd) {
	const market = await readMarketContract();
	await handleTx(
		market.setPositionMgr(mgrAddr, isAdd),
		"market.setPositionMgr"
	);
}

async function setOrderMgr(mgrAddr) {
	const market = await readMarketContract();
	await handleTx(
		market.setOrderMgr(mgrAddr),
		"market.setOrderMgr"
	);
}

module.exports = {
	deployMarket,
	readMarketContract,
	initialize,
	addPlugin,
	setOrderBooks,
	setPositionBook,
	setMarketValid,
	setPositionMgr,
	setOrderMgr,
};