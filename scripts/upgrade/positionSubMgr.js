const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");
const { deployPositionSubMgr } = require("../market/positionSubMgr")

async function replacePositionSubMgr(marketList) {
	const mgr = await deployPositionSubMgr(false)
	for (let index = 0; index < marketList.length; index++) {
		const market = marketList[index];
		await handleTx(
			market.setPositionMgr(mgr.address, false),
			"market.setPositionMgr.true"
		)
	}
}

module.exports = {
	replacePositionSubMgr
};