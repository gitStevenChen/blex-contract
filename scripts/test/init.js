const { deployGlobalMarket } = require("../market/deploy");
const { deployFee } = require("../fee/deployFeeAll");
const { deployReferral } = require("../referral/deploy");
const { deployOracle } = require("../oracle/deploy");
const { deployVault } = require("../vault/deploy");

const {
	deployOrConnect,
	readDeployedContract,
	handleTx,
	writeContractAddresses,
} = require("../utils/helpers");
const { readVaultRewardContract } = require("../vault/vaultReward");

async function deploy() {
	
	const usdc = await deployOrConnect("USDC", ["USDC", "USDC", "100000000000000000000"])
	const collateralToken = usdc.address;

	const writeJson = true

	const vaultName = "BLP";
	const vaultSymbol = "BLP"

	const defaultPriceDuration = 300;
	const defaultMaxPriceUpdateDelay = 3600;
	const defaultMinBlockInterval = 0;
	const defaultMaxDeviationBasisPoints = 1000;

	const configs = {
		priceDuration: defaultPriceDuration,
		maxPriceUpdateDelay: defaultMaxPriceUpdateDelay,
		minBlockInterval: defaultMinBlockInterval,
		maxDeviationBasisPoints: defaultMaxDeviationBasisPoints,
	}

	const feeContracts = await deployFee(writeJson);
	const lpContracts = await deployVault(
		feeContracts.feeRouter.address,
		collateralToken,
		vaultName,
		vaultSymbol,
		writeJson
	);
	const oracle = await deployOracle(configs, writeJson);
	const referral = await deployReferral(writeJson);
	const markets = await deployGlobalMarket(lpContracts.vaultRouter.address, writeJson);

	return {
		feeContracts: feeContracts,
		lpContracts: lpContracts,
		oracle: oracle,
		referral: referral,
		markets: markets,
	}
}

deploy().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
