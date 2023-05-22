const { grantRoleIfNotGranted } = require("../utils/helpers");
const { deployCoreVault, initialize: initCoreVault } = require("./coreVault");
const {
  deployVaultReward,
  initialize: initVaultReward,
} = require("./vaultReward");
const {
  deployVaultRouter,
  initialize: initVaultRouter,
} = require("./vaultRouter");
const {
  deployRewardDistributor,
  initialize: initDistributor,
} = require("./rewardDistributor");

async function deployVault(feeRouterAddr, asset, name, symbol, writeJson) {
  const coreVault = await deployCoreVault(asset, name, symbol, writeJson);
  const vaultReward = await deployVaultReward(writeJson);
  const vaultRouter = await deployVaultRouter(writeJson);
  const distributor = await deployRewardDistributor(writeJson);

  await initCoreVault(vaultRouter.address);
  await initVaultReward(
    coreVault.address,
    vaultRouter.address,
    feeRouterAddr,
    distributor.address
  );
  await initVaultRouter(coreVault.address, feeRouterAddr);
  await initDistributor(asset, vaultReward.address);

  await grantRoleIfNotGranted(coreVault, "ROLE_CONTROLLER", vaultReward.address);
  await grantRoleIfNotGranted(coreVault, "ROLE_CONTROLLER", vaultRouter.address);

  return {
    coreVault: coreVault,
    vaultReward: vaultReward,
    vaultRouter: vaultRouter,
    rewardDistributor: distributor,
  };
}

module.exports = {
  deployVault,
};
