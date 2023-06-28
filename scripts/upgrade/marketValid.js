const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");
const { readMarketValidContract, deployMarketValid } = require("../market/marketValid")

async function replaceMarketValid({ } = {}) {
	const valid_old = await readMarketValidContract();
	const conf = await valid_old.conf()
	const valid = await deployMarketValid()
	await handleTx(
		valid.setConfData(conf),
		"valid.setConfData"
	);
}

module.exports = {
	replaceMarketValid
};