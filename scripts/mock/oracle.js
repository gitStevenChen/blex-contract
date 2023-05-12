const { deployContract,deployOrConnect, readDeployedContract, handleTx } = require("../utils/helpers");

async function deployOracle() {
	const oracle = await deployContract("MockOracle", []);
	return oracle;
}

async function readOracleContract() {
	const oracle = await readDeployedContract("MockOracle");
	return oracle
}

async function setPrice(tokenAddr, price) {
	const oracle = await readDeployedContract("MockOracle");
	await handleTx(
		oracle.setPrice(tokenAddr, price),
		"oracle.setPrice"
	);
}

module.exports = {
	deployOracle,
	readOracleContract,
	setPrice,
};