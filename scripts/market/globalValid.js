const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployGlobalValid(writeJson) {
	const globalValid = await deployOrConnect("GlobalValid", []);

	const result = {
		GlobalValid: globalValid.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return globalValid;
}

async function readGlobalValidContract() {
	const globalValid = await readDeployedContract("GlobalValid");
	return globalValid;
}

async function setMaxSizeLimit(limit) {
	const globalValid = await readGlobalValidContract();
	await handleTx(
		globalValid.setMaxSizeLimit(limit),
		"globalValid.setMaxSizeLimit"
	);
}

async function setMaxNetSizeLimit(limit) {
	const globalValid = await readGlobalValidContract();
	await handleTx(
		globalValid.setMaxNetSizeLimit(limit),
		"globalValid.setMaxNetSizeLimit"
	);
}

async function setMaxUserNetSizeLimit(limit) {
	const globalValid = await readGlobalValidContract();
	await handleTx(
		globalValid.setMaxUserNetSizeLimit(limit),
		"globalValid.setMaxUserNetSizeLimit"
	);
}

async function setMaxMarketSizeLimit(marketAddr, limit) {
	const globalValid = await readGlobalValidContract();
	await handleTx(
		globalValid.setMaxMarketSizeLimit(marketAddr, limit),
		"globalValid.setMaxMarketSizeLimit"
	);
}

module.exports = {
	deployGlobalValid,
	readGlobalValidContract,
	setMaxSizeLimit,
	setMaxNetSizeLimit,
	setMaxUserNetSizeLimit,
	setMaxMarketSizeLimit,
};