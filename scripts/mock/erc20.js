const {
  readDeployedContract,
  handleTx,
  deployContract
} = require("../utils/helpers");

async function deployToken(name, symbol, label) {
  const token = await deployContract("ERC20Mocker", [name, symbol], label);
  return token;
}

async function readTokenContract() {
  const token = await readDeployedContract("ERC20Mocker");
  return token;
}

async function mint(toAddr, amount) {
  const token = await deployContract("ERC20Mocker", []);
  await handleTx(token.mint(toAddr, amount), "token.mint");
}

async function burn(toAddr, amount) {
  const token = await deployContract("ERC20Mocker", []);
  await handleTx(token.burn(toAddr, amount), "token.burn");
}

module.exports = {
  deployToken,
  readTokenContract,
  mint,
  burn,
};
