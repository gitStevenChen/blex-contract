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
  const token = await readTokenContract();
  await handleTx(token.mint(toAddr, amount), "token.mint");
}

async function burn(toAddr, amount) {
  const token = await readDeployedContract();
  await handleTx(token.burn(toAddr, amount), "token.burn");
}

async function approve(spender, amount) {
  const token = await readTokenContract();
  await handleTx(
    token.approve(spender, amount),
    "token.approve"
  );
}

module.exports = {
  deployToken,
  readTokenContract,
  mint,
  burn,
  approve,
};
