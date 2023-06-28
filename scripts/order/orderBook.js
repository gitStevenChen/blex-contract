const {
	deployContract,
	readDeployedContract2,
	handleTx,
	writeContractAddresses2,
} = require("../utils/helpers");

async function deployOrderBook(factoryAddr, writeJson, isLong, symbol) {
	const key = "orderBook" + isLong ? "Long" : "Short";
	const orderBook = await deployContract("OrderBook", [factoryAddr], key);

	const result = {
		[key]: orderBook.address,
	};
	if (writeJson) writeContractAddresses2(result, symbol)

	return orderBook;
}

async function readOrderBookContract({ isLong, symbol } = {}) {
	const key = "orderBook" + (isLong ? "Long" : "Short");
	const orderBook = await readDeployedContract2({
		name: "OrderBook",
		label: key,
		symbol: symbol
	});
	return orderBook;
}

async function initializeOrderBook({ openStoreAddr, closeStoreAddr, isLong, symbol } = {}) {
	const orderBook = await readOrderBookContract({
		isLong: isLong,
		symbol: symbol
	});
	await handleTx(
		orderBook.initialize(isLong, openStoreAddr, closeStoreAddr),
		"orderBook.initialize"
	);
}

module.exports = {
	deployOrderBook,
	readOrderBookContract,
	initializeOrderBook,
};
