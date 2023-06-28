const { readFeeVaultContract } = require("../fee/feeVault.js");
const { readFundFeeContract } = require("../fee/fundFee.js");
const { deployFeeRouter, initFeeRouter } = require("../fee/feeRouter.js");
const { grantRoleIfNotGranted, revokeRoleIfGranted } = require("../utils/helpers.js");

const { readPositionBookContract } = require("../position/positionBook.js");
const { readOrderBookContract } = require("../order/orderBook.js");
const { readMarketValidContract } = require("../market/marketValid.js");
const { readOracleContract } = require("../oracle/price.js");
const { readPositionSubMgrContract } = require("../market/positionSubMgr.js");
const { readPositionAddMgrContract } = require("../market/positionAddMgr.js");
const { readVaultRouterContract } = require("../vault/vaultRouter.js");
const { readGlobalValidContract } = require("../market/globalValid.js");
const { readOrderMgrContract } = require("../market/orderMgr.js");
const { readMarketContract, setContracts } = require("../market/market.js");
const { readMarketFactoryContract } = require("../market/marketFactory.js");

async function replaceFeeRouter(writeJson = true, isInit = true) {
	const marketFac = await readMarketFactoryContract()
	const feeRouter = await deployFeeRouter(marketFac.address, writeJson);

	const feeVault = await readFeeVaultContract();
	const fundFee = await readFundFeeContract();
	if (isInit) {
		await initFeeRouter(feeVault.address, fundFee.address);
	}

	const priceFeed = await readOracleContract();
	const positionSubMgr = await readPositionSubMgrContract();
	const positionAddMgr = await readPositionAddMgrContract();
	const vaultRouter = await readVaultRouterContract();
	const globalValid = await readGlobalValidContract();
	const orderMgr = await readOrderMgrContract();

	await grantRoleIfNotGranted(feeVault, "ROLE_CONTROLLER", feeRouter.address);
	await grantRoleIfNotGranted(fundFee, "ROLE_CONTROLLER", feeRouter.address);
	const symbols = ["ETH", "BTC"]
	for (let index = 0; index < symbols.length; index++) {
		const symbol = symbols[index];
		const positionBook = await readPositionBookContract(symbol);
		const orderBookLong = await readOrderBookContract({ isLong: true, symbol: symbol });
		const orderBookShort = await readOrderBookContract({ isLong: false, symbol: symbol });
		const marketValid = await readMarketValidContract(symbol);
		await setContracts(
			[
				positionBook,
				orderBookLong,
				orderBookShort,
				marketValid,
				priceFeed,
				positionSubMgr,
				positionAddMgr,
				feeRouter,
				vaultRouter,
				globalValid,
				orderMgr
			],
			symbol
		);
		const market = await readMarketContract(symbol)
		await grantRoleIfNotGranted(
			feeRouter,
			"ROLE_CONTROLLER",
			market.address,
			"feeRouter.grant.market"
		)
		await setFeeAndRates(
			market.address,
			["100000", "100000", "0", "1000000000000000000", "5000000000000000000"]
		)
	}

	return feeRouter
}

module.exports = {
	replaceFeeRouter
};