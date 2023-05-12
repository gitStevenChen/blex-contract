const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	grantRoleIfNotGranted,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployCoreVault(asset, name, symbol, writeJson) {
	const vault = await deployOrConnect("CoreVault", [asset, name, symbol]);

	const result = {
		CoreVault: vault.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return vault;
}

async function readCoreVaultContract() {
	const vault = await readDeployedContract("CoreVault");
	return vault
}

async function initialize(vaultRouterAddr) {
	const vault = await readCoreVaultContract();
	await handleTx(
		vault.initialize(vaultRouterAddr),
		"coreVault.initialize"
	);
}

async function setLpFee(isBuy, fee) {
	const vault = await readCoreVaultContract();
	await handleTx(
		vault.setLpFee(isBuy, fee),
		"coreVault.setLpFee"
	);
}

async function setCooldownDuration(duration) {
	const vault = await readCoreVaultContract();
	await handleTx(
		vault.setCooldownDuration(duration),
		"coreVault.setCooldownDuration"
	);
}

module.exports = {
	deployCoreVault,
	readCoreVaultContract,
	initialize,
	setLpFee,
	setCooldownDuration,
};