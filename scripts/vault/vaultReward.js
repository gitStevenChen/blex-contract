const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	grantRoleIfNotGranted,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployVaultReward(writeJson) {
	const reward = await deployOrConnect("VaultReward", []);

	const result = {
		VaultReward: reward.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return reward;
}

async function readVaultRewardContract() {
	const reward = await readDeployedContract("VaultReward");
	return reward;
}

async function initialize(coreVaultAddr, vaultRouterAddr, feeRouterAddr) {
	const reward = await readVaultRewardContract();
	await handleTx(
		reward.initialize(coreVaultAddr, vaultRouterAddr, feeRouterAddr),
		"vaultReward.initialize"
	);
}

module.exports = {
	deployVaultReward,
	readVaultRewardContract,
	initialize,
};