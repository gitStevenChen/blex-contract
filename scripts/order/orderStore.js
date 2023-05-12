const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployOrderStore(factoryAddr, writeJson, label) {
	const key = "OrderStore"+ (label); 
	const orderStore = await deployOrConnect("OrderStore", [factoryAddr], key);

	const result = {
		[key]:  orderStore.address,
	};
	if (writeJson)
		writeContractAddresses(result)

	return orderStore;
}

async function readOrderStoreContract(label) {
	const key = "OrderStore"+ (label); 
	const orderStore = await readDeployedContract(key);
	return orderStore;
}

async function initialize(isLong, label) {
	const orderStore  = await readOrderStoreContract(label);
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