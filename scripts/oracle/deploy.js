const { deployChainPriceFeed } = require("./chainPriceFeed.js");
const {
	deployFastPriceFeed,
	setFastPricePriceFeed,
} = require("./fastPriceFeed.js");

const {
	deployPrice,
	setFastPriceFeed,
	setChainPriceFeed,
} = require("./price.js");

async function deployOracle(configs, writeJson) {
	const chainPrice = await deployChainPriceFeed(writeJson);
	const fastPrice = await deployFastPriceFeed(
		configs.priceDuration, 
		configs.maxPriceUpdateDelay, 
		configs.minBlockInterval, 
		configs.maxDeviationBasisPoints,
		writeJson
	);
	const price = await deployPrice(writeJson);
	
	await setFastPricePriceFeed(chainPrice.address);
	await setFastPriceFeed(fastPrice.address);
	await setChainPriceFeed(chainPrice.address);
	
	return {
		price:	    price,
		chainPrice: chainPrice,
		fastPrice:  fastPrice,
	}
}

module.exports = {
	deployOracle,
};