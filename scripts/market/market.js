
const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
	readDeployedContract2
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

/**
 * @param {ETH or BTC} symbol 
 * @returns market contract
 */
async function readMarketContract(symbol) {
	const market = await readDeployedContract2({ name: "Market", symbol: symbol });
	return market;
}

async function initialize(name, initAddrs) {
	const market = await readMarketContract();
	await handleTx(
		market.initialize(initAddrs, name),
		"market.initialize"
	);
}

async function addPlugin(market, pluginAddr) {

	await handleTx(
		market.addPlugin(pluginAddr),
		"market.addPlugin"
	);
}

async function setOrderBooks(market, orderBookLongAddr, orderBookShortAddr) {
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

async function setContracts(contracts, symbol) {
	const market = await readMarketContract(symbol)
	const contractFactory = await ethers.getContractFactory("OrderMgr")
	const mgr = await contractFactory.attach(market.address)

	const newAddresses = []
	for (let index = 0; index < contracts.length; index++) {
		const element = contracts[index];
		newAddresses.push(element.address)
	}
	await handleTx(
		mgr.setContracts(newAddresses),
		"mgr.setContracts"
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
	setContracts
};