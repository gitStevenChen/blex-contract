
const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
	deployContract
} = require("../utils/helpers");
const { deployPositionAddMgr } = require("../market/positionAddMgr")

async function replacePositionAddMgr(marketList) {
	const mgr = await deployPositionAddMgr(false)
	for (let index = 0; index < marketList.length; index++) {
		const market = marketList[index];
		await handleTx(
			market.setPositionMgr(mgr.address, true),
			"market.setPositionMgr.true"
		)
	}
}

module.exports = {
	replacePositionAddMgr
};