const {
  deployOrConnect,
  readDeployedContract,
  handleTx,
  writeContractAddresses,
} = require("../utils/helpers");

async function deployVaultFactory(writeJson) {
  const factory = await deployOrConnect("VaultFactory", []);

  const result = {
    VaultFactory: factory.address,
  };
  if (writeJson) writeContractAddresses(result);

  return factory;
}

async function readVaultFactoryContract() {
  return await readDeployedContract("VaultFactory");
}

async function initialize(
  asset,
  feeRouter,
  rewardDistributor,
  coreVault,
  vaultRouter,
  vaultReward
) {
  const factory = await readVaultFactoryContract();
  await handleTx(
    factory.initialize(
      asset,
      feeRouter,
      rewardDistributor,
      coreVault,
      vaultRouter,
      vaultReward
    ),
    "VaultFactory.initialize"
  );
}

async function setMarket(marketAddr) {
  const factory = await readVaultFactoryContract();
  await handleTx(factory.setMarket(marketAddr), "VaultFactory.setMarket");
}

module.exports = {
  deployVaultFactory,
  readVaultFactoryContract,
  initialize,
  setMarket,
};
