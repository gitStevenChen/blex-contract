const {
	deployOrderBook : deployOB,
	initialize,
} = require("./orderBook.js");
const { 
	deployOrderStore, 
} = require("./orderStore.js");

async function deployOrderBook(factoryAddr, isLong, writeJson) {
	let orderStoreKey1 = "0";
	let orderStoreKey2 = "1";
	let orderBookKey = "Long";

	if (!isLong) {
		orderStoreKey1 = "2";
		orderStoreKey2 = "3";
		orderBookKey = "Short";
  	}

	const orderStoreOpen = await deployOrderStore(factoryAddr, writeJson, orderStoreKey1);
	const orderStoreClose = await deployOrderStore(factoryAddr, writeJson, orderStoreKey2);

	const orderBook = await deployOB(factoryAddr, writeJson, orderBookKey);
	// await initialize(orderStoreOpen, orderStoreOpen, isLong, orderBookKey);

	return {
		orderBook: orderBook,
		orderStoreOpen: orderStoreOpen,
		orderStoreClose: orderStoreClose,
	}
}

module.exports = {
	deployOrderBook,
};