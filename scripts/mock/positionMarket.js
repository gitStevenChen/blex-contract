const {
  deployOrConnect,
  readDeployedContract,
  handleTx,
  deployContract
} = require("../utils/helpers");

async function deployPositionMarket() {
  const positionMarket = await deployContract("MockPositionMarket", []);
  return positionMarket;
}

async function readPositionMarketContract() {
  const positionMarket = await readDeployedContract("MockPositionMarket");
  return positionMarket;
}

async function setGlobalLongSize(positionMarket, size) {
  await handleTx(
    positionMarket.setGlobalLongSize(size),
    "positionMarket.setGlobalLongSize"
  );
}

async function setGlobalShortSize(positionMarket, size) {
  await handleTx(
    positionMarket.setGlobalShortSize(size),
    "positionMarket.setGlobalShortSize"
  );
}

async function setMarketLongSize(positionMarket, marketAddr, size) {
  await handleTx(
    positionMarket.setMarketLongSize(marketAddr, size),
    "positionMarket.setMarketLongSize"
  );
}

async function setMarketShortSize(positionMarket, marketAddr, size) {
  await handleTx(
    positionMarket.setMarketShortSize(marketAddr, size),
    "positionMarket.setMarketShortSize"
  );
}

async function setUserLongSize(positionMarket, account, size) {
  await handleTx(
    positionMarket.setUserLongSize(account, size),
    "positionMarket.setUserLongSize"
  );
}

async function setUserShortSize(positionMarket, account, size) {
  await handleTx(
    positionMarket.setUserShortSize(account, size),
    "positionMarket.setUserShortSize"
  );
}

module.exports = {
  deployPositionMarket,
  readPositionMarketContract,
  setGlobalLongSize,
  setGlobalShortSize,
  setMarketLongSize,
  setMarketShortSize,
  setUserLongSize,
  setUserShortSize,
};
