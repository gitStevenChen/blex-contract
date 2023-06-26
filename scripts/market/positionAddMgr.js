
const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
	deployContract
} = require("../utils/helpers");

async function deployPositionAddMgr(writeJson) {
	const positionAddMgr = await deployContract("PositionAddMgr", []);

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