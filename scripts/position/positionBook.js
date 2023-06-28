const {
  deployOrConnect,
  readDeployedContract2,
  handleTx,
  grantRoleIfNotGranted,
  writeContractAddresses,
} = require("../utils/helpers");

async function deployPositionBook(factotyAddr, writeJson) {
  const pb = await deployOrConnect("PositionBook", [factotyAddr]);

  const result = {
    PositionBook: pb.address
  };
  if (writeJson)
    writeContractAddresses(result)

  return pb;
}

async function readPositionBookContract(symbol) {
  const pb = await readDeployedContract2({ name: "PositionBook", symbol: symbol });
  return pb
}

async function initPositionBook(marketAddr) {
  const pb = await readDeployedContract("PositionBook");

  await handleTx(
    pb.initialize(marketAddr),
    "positionBook.initialize"
  );
}


module.exports = {
  deployPositionBook,
  readPositionBookContract,
  initPositionBook,
};
