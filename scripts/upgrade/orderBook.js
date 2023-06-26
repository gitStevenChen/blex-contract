const {
	deployContract,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
	grantRoleIfNotGranted
} = require("../utils/helpers");

const { readMarketFactoryContract } = require("../market/marketFactory")
const { deployOrderBook } = require("../order/orderBook")
const { setOrderBooks } = require("../market/market")
const { readOrderStoreContract } = require("../order/orderStore")
const { initializeOrderBook } = require("../order/orderBook")

async function replaceOrderBook(marketList, symbols) {
	const marketFac = await readMarketFactoryContract()
	for (let index = 0; index < marketList.length; index++) {
		const market = marketList[index];
		const symbol = symbols[index];
		const ob0 = await deployOrderBook(marketFac.address, true, "Long", symbol)
		const ob1 = await deployOrderBook(marketFac.address, true, "Short", symbol)
		await setOrderBooks(market, ob0.address, ob1.address)
		const obs = [ob0, ob1]
		for (let j = 0; j < obs.length; j++) {
			const ob = obs[j];
			const isLong = j == 0
			const isOpens = [true, false]
			const oss = []
			for (let k = 0; k < isOpens.length; k++) {
				const isOpen = isOpens[k];
				const os = await readOrderStoreContract({
					symbol: symbol,
					isLong: isLong,
					isOpen: isOpen
				})
				oss.push(os)
				await grantRoleIfNotGranted(os, "ROLE_CONTROLLER", ob, "os grant ob")
			}
			await grantRoleIfNotGranted(ob, "ROLE_CONTROLLER", market, "ob grant market")
		}
	}
}

module.exports = {
	replaceOrderBook
};