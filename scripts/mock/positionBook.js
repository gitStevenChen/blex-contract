const {
  deployOrConnect,
  readDeployedContract,
  handleTx,
  deployContract
} = require("../utils/helpers");

async function deployPositionBook() {
  const book = await deployContract("PositionBookMocker", []);
  return book;
}

async function readPositionBookContract() {
  const book = await readDeployedContract("PositionBookMocker");
  return book;
}

async function setFeeRouter(positionBook, feeRouter) {
  await handleTx(
    positionBook.setFeeRouter(feeRouter),
    "positionBook.setFeeRouter"
  );
}

async function setOracle(positionBook, oracleAddr) {
  await handleTx(
    positionBook.setOracle(oracleAddr),
    "positionBook.setOracle"
  );
}

async function setPositionMarket(positionBook, positionMarketAddr) {
  await handleTx(
    positionBook.setPositionMarket(positionMarketAddr),
    "positionBook.setPositionMarket"
  );
}

async function increasePosition(positionBook, account, market, collateral, sizeDelta, markPrice, isLong) {
    await handleTx(
        positionBook.increasePosition(account, market, collateral, sizeDelta, markPrice, isLong),
        "positionBook.increasePosition"
    );
}


module.exports = {
  deployPositionBook,
  readPositionBookContract,
  setFeeRouter,
  setOracle,
  setPositionMarket,
  increasePosition,
};
