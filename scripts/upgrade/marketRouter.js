const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
	upgradeContract
} = require("../utils/helpers");
const { readMarketValidContract, deployMarketValid } = require("../market/marketValid")

async function replaceMarketRouter({ } = {}) {
	await upgradeContract("MarketRouter")
}

module.exports = {
	replaceMarketRouter
};