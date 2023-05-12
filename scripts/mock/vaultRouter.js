const { deployOrConnect, readDeployedContract, handleTx } = require("../utils/helpers");

async function deployVaultRouter() {
	const router = await deployOrConnect("MockVaultRouter", []);
	return router;
}

async function readVaultRouterContract() {
	const router = await readDeployedContract("MockVaultRouter");
	return router;
}

async function setFundLimit(limit) {
	const router = await deployOrConnect("MockVaultRouter", []);
	await handleTx(
		router.setFundLimit(limit),
		"vaultRouter.setFundLimit"
	);
}

async function setUSDBalance(amount) {
	const router = await deployOrConnect("MockVaultRouter", []);
	await handleTx(
		router.setUSDBalance(amount),
		"vaultRouter.setUSDBalance"
	);
}

module.exports = {
	deployVaultRouter,
	readVaultRouterContract,
	setFundLimit,
	setUSDBalance,
};