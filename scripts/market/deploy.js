const {
	deployGlobalValid,
	readGlobalValidContract,
	setMaxSizeLimit,
	setMaxNetSizeLimit,
	setMaxUserNetSizeLimit,
	setMaxMarketSizeLimit,
} = require("./globalValid.js");

const {
	deployMarketFactory,
	readMarketFactoryContract,
	createMarket: factoryCreateMarket,
} = require("./marketFactory.js");

const {
	deployMarketReader,
	readMarketReaderContract,
	initializeReader,
} = require("./marketReader.js");

const {
	deployMarketRouter,
	readMarketRouterContract,
	initializeRouter,
	addMarket,
	removeMarket,
} = require("./marketRouter.js");

const {
	deployMarketValid,
	readMarketValidContract,
	setMarketValidConf,
	setMarketValidConfData,
} = require("./marketValid.js");

const {
	deployMarketValidReader,
	readMarketValidReaderContract,
} = require("./marketValidReader.js");

const {
	deployOrderMgr,
	readOrderMgrContract,
} = require("./orderMgr.js");

const {
	deployPositionAddMgr,
	readPositionAddMgrContract,
} = require("./positionAddMgr.js");

const {
	deployPositionSubMgr,
	readPositionSubMgrContract,
} = require("./positionSubMgr.js");

const {
	deployMarket,
	readMarketContract,
	initialize,
	addPlugin,
	setOrderBooks,
	setPositionBook,
	setMarketValid,
	setPositionMgr,
	setOrderMgr,
} = require("./market.js");

const {
	deployPositionBook,
	readPositionBookContract,
	initPositionBook,
} = require("../position/positionBook.js");

const {
	deployOrderBook
} = require("../order/deployAll.js");

async function deployGlobalMarket(vaultRouterAddr, writeJson) {
	const globalValid = await deployGlobalValid(writeJson);
	const factory = await deployMarketFactory(writeJson);
	const marketReader = await deployMarketReader(factory.address, writeJson);
	const marketRouter = await deployMarketRouter(writeJson);
	const orderMgr = await deployOrderMgr(writeJson);
	const positionAddMgr = await deployPositionAddMgr(writeJson);
	const positionSubMgr = await deployPositionSubMgr(writeJson);

	await initializeReader(marketRouter.address, vaultRouterAddr);
	await initializeRouter(globalValid.address, vaultRouterAddr);

	return {
		globalValid: globalValid,
		factory: factory,
		marketReader: marketReader,
		marketRouter: marketRouter,
		orderMgr: orderMgr,
		positionAddMgr: positionAddMgr,
		positionSubMgr: positionSubMgr,
	}
}

/**
 * @description: 
 * @param {string} name
 * @param {object{
 * 		factory: string
 * 		oracle: string,		// oracle address
 * 		indexToken: string, 	// indexToken address
 * 		feeRouter: string,	// feeRouter address
 * 		vaultRouter: string,	// vaultRouter address
 * 		collateralToken: string	// collateralToken address
 * 		positionSubMgr: string	// positionSubMgr address
 * 		positionAddMgr: string
 * 		marketRouter: string
 * 		globalValid: string
 * 		orderMgr: string
 * 	}} contracts
 * @param {object {
 * 	minSlippage: int,
 * 	maxSlippage: int,
 * 	minLeverage: int,
 * 	maxLeverage: int,
 * 	maxTradeAmount: int,
 * 	minPay: int,
 * 	minCollateral: int,
 * 	allowOpen: bool,
 * 	allowClose: bool,
 * 	tokenDigits: int
 * }} configs
 * @param {bool} writeJson
 */
async function createMarket(name, contracts, configs, writeJson) {
	const market = await deployMarket(contracts.factory, writeJson);
	const marketValid = await deployMarketValid(contracts.factory, writeJson);
	const positionBook = await deployPositionBook(contracts.factory, writeJson);
	const orderBookLongContracts = await deployOrderBook(contracts.factory, true, writeJson);
	const orderBookShortContracts = await deployOrderBook(contracts.factory, false, writeJson);

	const createInputs = {
		_name: name,
		_marketAddress: market.address,
		addrs: [
			positionBook.address,
			orderBookLongContracts.orderBook.address,
			orderBookShortContracts.orderBook.address,
			marketValid.address,
			contracts.oracle,
			contracts.positionSubMgr,
			contracts.positionAddMgr,
			contracts.indexToken,
			contracts.feeRouter,
			contracts.marketRouter,
			contracts.vaultRouter,
			contracts.collateralToken,
			contracts.globalValid,
			contracts.orderMgr
		],
		_openStoreLong: orderBookLongContracts.orderStoreOpen.address,
		_closeStoreLong: orderBookLongContracts.orderStoreClose.address,
		_openStoreShort: orderBookShortContracts.orderStoreOpen.address,
		_closeStoreShort: orderBookShortContracts.orderStoreClose.address,
		_minSlippage: configs.minSlippage,
		_maxSlippage: configs.maxSlippage,
		_minLeverage: configs.minLeverage,
		_maxLeverage: configs.maxLeverage,
		_maxTradeAmount: configs.maxTradeAmount,
		_minPay: configs.minPay,
		_minCollateral: configs.minCollateral,
		_allowOpen: configs.allowOpen,
		_allowClose: configs.allowClose,
		_tokenDigits: configs.tokenDigits
	};

	await factoryCreateMarket(createInputs);

	return {
		market: market,
		positionBook: positionBook,
		marketValid: marketValid,
		orderBookLong: orderBookLongContracts.orderBook,
		orderBookShort: orderBookShortContracts.orderBook,
		openStoreLong: orderBookLongContracts.orderStoreOpen.address,
		closeStoreLong: orderBookLongContracts.orderStoreClose.address,
		openStoreShort: orderBookShortContracts.orderStoreOpen.address,
		closeStoreShort: orderBookShortContracts.orderStoreClose.address,
	}
}


module.exports = {
	deployGlobalMarket,
	createMarket,
};