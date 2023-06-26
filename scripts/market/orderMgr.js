const {
	deployContract,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");
const { readMarketContract } = require("./market")

async function deployOrderMgr(writeJson) {
	const mgr = await deployContract("OrderMgr", []);
	const result = {
		OrderMgr: mgr.address
	};
	if (writeJson) writeContractAddresses(result)
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