const {
  deployOrConnect,
  readDeployedContract,
  handleTx,
  grantRoleIfNotGranted,
  writeContractAddresses,
} = require("../utils/helpers");

async function deployGlobalValid(writeJson) {
  const globalValid = await deployOrConnect("GlobalValid", []);

  const result = {
    GlobalValid: globalValid.address
  };
  if (writeJson)
    writeContractAddresses(result)

  return globalValid;
}

async function readGlobalValidContract() {
  return await readDeployedContract("GlobalValid");
}

async function setMaxSizeLimit(limit) {
  const globalValid = await readDeployedContract("GlobalValid");

  await handleTx(
    globalValid.setMaxSizeLimit(limit),
    "globalValid.setMaxSizeLimit"
  );
}

async function setMaxNetSizeLimit(limit) {
  const globalValid = await readDeployedContract("GlobalValid");

  await handleTx(
    globalValid.setMaxNetSizeLimit(limit),
    "globalValid.setMaxNetSizeLimit"
  );
}

async function setMaxUserNetSizeLimit(limit) {
  const globalValid = await readDeployedContract("GlobalValid");

  await handleTx(
    globalValid.setMaxUserNetSizeLimit(limit),
    "globalValid.setMaxUserNetSizeLimit"
  );
}

async function setMaxMarketSizeLimit(marketAddr, limit) {
  const globalValid = await readDeployedContract("GlobalValid");

  await handleTx(
    globalValid.setMaxMarketSizeLimit(marketAddr, limit),
    "globalValid.setMaxMarketSizeLimit"
  );
}

module.exports = {
  deployGlobalValid,
  readGlobalValidContract,
  setMaxSizeLimit,
  setMaxNetSizeLimit,
  setMaxUserNetSizeLimit,
  setMaxMarketSizeLimit,
};

