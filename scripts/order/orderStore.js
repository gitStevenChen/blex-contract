const {
	deployContract,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
	readDeployedContract2
} = require("../utils/helpers");

async function deployOrderStore(factoryAddr, writeJson, isLong, isOpen, symbol) {
	let label
	if (isLong && isOpen) label = "0"
	if (isLong && !isOpen) label = "1"
	if (!isLong && isOpen) label = "2"
	if (!isLong && !isOpen) label = "3"
	const key = "OrderStore" + (label);
	const orderStore = await deployContract("OrderStore", [factoryAddr], key);

	const result = {
		[key]: orderStore.address,
	};
	if (writeJson) writeContractAddresses2(result, symbol)

	return orderStore;
}

async function readOrderStoreContract({ symbol, isLong, isOpen } = {}) {
	if (isLong && isOpen) label = "0"
	if (isLong && !isOpen) label = "1"
	if (!isLong && isOpen) label = "2"
	if (!isLong && !isOpen) label = "3"
	const key = "OrderStore" + (label);
	const orderStore = await readDeployedContract2({ label: key, symbol });
	return orderStore;
}

async function initialize(isLong, label) {
	const orderStore = await readOrderStoreContract(label);
	await handleTx(
		orderStore.initialize(isLong),
		"orderStore.initialize"
	);
}

module.exports = {
	deployOrderStore,
	readOrderStoreContract,
	initialize,
};