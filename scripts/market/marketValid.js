const {
	deployContract,
	deployOrConnect,
	readDeployedContract2,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");

async function deployMarketValid(factoryAddr, writeJson) {
	const valid = await deployContract("MarketValid", [factoryAddr]);

	const result = {
		MarketValid: valid.address
	};
	if (writeJson)
		writeContractAddresses(result)

	return valid;
}

async function readMarketValidContract(symbol) {
	const valid = await readDeployedContract2({ name: "MarketValid", symbol: symbol });
	return valid;
}

async function setMarketValidConf(minSlippage, maxSlippage, minLeverage,
	maxLeverage, maxTradeAmount, minPay, minCollateral,
	allowOpen, allowClose, tokenDigits
) {
	const valid = await readMarketValidContract();
	await handleTx(
		valid.setConf(
			minSlippage, maxSlippage, minLeverage, maxLeverage,
			maxTradeAmount, minPay, minCollateral,
			allowOpen, allowClose,
			tokenDigits
		),
		"valid.setConf"
	);
}

async function setMarketValidConfData(data) {
	const router = await readMarketRouterContract();
	await handleTx(
		router.setConfData(data),
		"router.setConfData"
	);
}


module.exports = {
	deployMarketValid,
	readMarketValidContract,
	setMarketValidConf,
	setMarketValidConfData,

};