const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployOrderMgr(writeJson) {
	const mgr = await deployOrConnect("OrderMgr", []);

	const result = {
		OrderMgr: mgr.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return mgr;
}

async function readOrderMgrContract() {
	const mgr = await readDeployedContract("OrderMgr");
	return mgr;
}

module.exports = {
	deployOrderMgr,
	readOrderMgrContract,
};