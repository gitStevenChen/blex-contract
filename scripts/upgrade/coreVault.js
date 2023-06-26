const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
	upgradeContract
} = require("../utils/helpers");
const { readMarketValidContract, deployMarketValid } = require("../market/marketValid")

async function replaceCoreVault({ } = {}) {
	await upgradeContract("CoreVault")
}

module.exports = {
	replaceCoreVault
};