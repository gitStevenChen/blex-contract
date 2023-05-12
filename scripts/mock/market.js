const {
  deployContract,
  readDeployedContract,
  handleTx,
  grantRoleIfNotGranted,
  writeContractAddresses,
} = require("../utils/helpers");

async function deployMarket(writeJson) {
  const market = await deployContract("MockMarket", []);

  const result = {
    positionValid: market.address
  };
  if (writeJson)
    writeContractAddresses(result)

  return market;
}

async function readMarketContract() {
	const market = await readDeployedContract("MockMarket");
	return market
}

async function setPositionBook(positionBookAddr) {
	const market = await readDeployedContract("MockMarket");
	await handleTx(
		market.setPositionBook(positionBookAddr),
		"market.setPositionBook"
	);
}

module.exports = {
	deployMarket,
	readMarketContract,
	setPositionBook,
};