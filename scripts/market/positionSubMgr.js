const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployPositionSubMgr(writeJson) {
	const positionSubMgr = await deployOrConnect("PositionSubMgr", []);

	const result = {
		PositionAddMgr: positionSubMgr.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return positionSubMgr;
}

async function readPositionSubMgrContract() {
	const positionSubMgr = await readDeployedContract("PositionSubMgr");
	return positionSubMgr;
}

module.exports = {
	deployPositionSubMgr,
	readPositionSubMgrContract,
};