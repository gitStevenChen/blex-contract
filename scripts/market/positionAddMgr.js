const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployPositionAddMgr(writeJson) {
	const positionAddMgr = await deployOrConnect("PositionAddMgr", []);

	const result = {
		PositionAddMgr: positionAddMgr.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return positionAddMgr;
}

async function readPositionAddMgrContract() {
	const positionAddMgr = await readDeployedContract("PositionAddMgr");
	return positionAddMgr;
}

module.exports = {
	deployPositionAddMgr,
	readPositionAddMgrContract,
};