const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	grantRoleIfNotGranted,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployVaultRouter(writeJson) {
	const vaultRouter = await deployOrConnect("VaultRouter", []);

	const result = {
		VaultRouter: vaultRouter.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return vaultRouter;
}

async function readVaultRouterContract() {
	const vaultRouter = await readDeployedContract("VaultRouter");
	return vaultRouter;
}

async function initialize(coreVaultAddr, feeRouterAddr) {
	const vaultRouter = await readVaultRouterContract();
	await handleTx(
		vaultRouter.initialize(coreVaultAddr, feeRouterAddr),
		"vaultRouter.initialize"
	);
}

async function setMarket(marketAddr, vaultAddr) {
	const vaultRouter = await readVaultRouterContract();
	await handleTx(
		vaultRouter.setMarket(marketAddr, vaultAddr),
		"vaultRouter.setMarket"
	);
	await grantRoleIfNotGranted(
		vaultRouter,
		"ROLE_CONTROLLER",
		market,
		"feeRouter.grant.market"
	)
}

module.exports = {
	deployVaultRouter,
	readVaultRouterContract,
	initialize,
	setMarket,
};