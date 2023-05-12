const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployOrderBook(factoryAddr, writeJson, label) {
	const key = "OrderBook"+(label); 
	const orderBook = await deployOrConnect("OrderBook", [factoryAddr], key);

	const result = {
		[key]: orderBook.address,
	};
	if (writeJson)
		writeContractAddresses(result)

	return orderBook;
}

async function readOrderBookContract(label) {
	const key = "OrderBook"+(label); 
	const orderBook = await readDeployedContract(key);
	return orderBook;
}

async function initialize(openStoreAddr, closeStoreAddr, isLong, label) {
	const orderBook  = await readOrderBookContract(label);
	await handleTx(
		orderBook.initialize(isLong, openStoreAddr, closeStoreAddr),
		"orderBook.initialize"
	);
}

module.exports = {
	deployOrderBook,
	readOrderBookContract,
	initialize,
};
