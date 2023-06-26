const {
	deployContract,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

const { deployOrderMgr } = require("../market/orderMgr")

async function replaceOrderMgrContract(marketList) {
	const mgr = await deployOrderMgr(true)
	for (let index = 0; index < marketList.length; index++) {
		const market = marketList[index];
		await handleTx(
			market.setOrderMgr(mgr.address),
			"market.setOrderMgr"
		)
	}
}

module.exports = {
	replaceOrderMgrContract
};