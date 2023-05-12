const { deployFeeVault } = require("./feeVault.js");
const { deployFundFee } = require("./fundFee.js");
const { deployFeeRouter, initFeeRouter } = require("./feeRouter.js");
const { grantRoleIfNotGranted } = require("../utils/helpers")

async function deployFee(factoryAddr, writeJson, isInit = true) {
	const feeVault = await deployFeeVault(writeJson);
	const fundFee = await deployFundFee(feeVault.address, writeJson);
	const feeRouter = await deployFeeRouter(factoryAddr, writeJson);
	if (isInit) {
		await initFeeRouter(feeVault.address, fundFee.address);
	}

	await grantRoleIfNotGranted(feeVault, "ROLE_CONTROLLER", fundFee.address);
	await grantRoleIfNotGranted(feeVault, "ROLE_CONTROLLER", feeRouter.address);
	await grantRoleIfNotGranted(fundFee, "ROLE_CONTROLLER", feeRouter.address);

	return {
		feeRouter: feeRouter,
		fundFee: fundFee,
		feeVault: feeVault,
	}
}

module.exports = {
	deployFee
};