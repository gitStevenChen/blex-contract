const { 
	deployCoreVault, 
	initialize: initCoreVault 
} = require("./coreVault");
const { 
	deployVaultReward, 
	initialize: initVaultReward 
} = require("./vaultReward");
const {
	deployVaultRouter,
	initialize: initVaultRouter,
} = require("./vaultRouter");

async function deployVault(feeRouterAddr, asset, name, symbol, writeJson) {
	const coreVault = await deployCoreVault(asset, name, symbol, writeJson);
	const vaultReward = await deployVaultReward(writeJson);
	const vaultRouter = await deployVaultRouter(writeJson);

	await initCoreVault(vaultRouter.address);
	await initVaultReward(coreVault.address, vaultRouter.address, feeRouterAddr);
	await initVaultRouter(coreVault.address, feeRouterAddr);

	return {
		coreVault:   coreVault,
		vaultReward: vaultReward,
		vaultRouter: vaultRouter,
	}
}

module.exports = {
	deployVault,
};