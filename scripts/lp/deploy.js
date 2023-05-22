const {
  deployOrConnect,
  waitTx,
  grantRoleIfNotGranted,
} = require("../utils/helpers");

const { utils } = require("ethers");

// call this function need deploy usdc first
async function deployAll(usdc, feeRouter, isInit = true) {
  const vault = await deployOrConnect("CoreVault", [
    usdc.address,
    "BLP",
    "BLP",
  ]);
  const vaultRouter = await deployOrConnect("VaultRouter");
  const vaultReward = await deployOrConnect("VaultReward");
  const rewardDistributor = await deployOrConnect("RewardDistributor");

  const setMarketLP = ({ market, vault } = {}) => {
    return waitTx(
      vaultRouter.setMarket(market.address, vault.address),
      "setMarket"
    );
  };

  const initLP = async ({
    vault,
    vaultRouter,
    vaultReward,
    feeRouter,
    rewardDistributor,
  } = {}) => {
    await waitTx(
      vaultRouter.initialize(vault.address, feeRouter.address),
      "vaultRouter.initialize"
    );

    await waitTx(
      vaultReward.initialize(
        vault.address,
        vaultRouter.address,
        feeRouter.address,
        rewardDistributor.address
      ),
      "vaultReward.initialize"
    );

    await waitTx(
      rewardDistributor.initialize(await vault.asset(), vaultReward.address),
      "rewardDistributor.initialize"
    );
    console.log("vaultRouter", vaultRouter.address);
    await waitTx(vault.initialize(vaultRouter.address), "vault.initialize");

    await grantRoleIfNotGranted(vault, "ROLE_CONTROLLER", vaultReward.address);
    await grantRoleIfNotGranted(vault, "ROLE_CONTROLLER", vaultRouter.address);
  };

  return {
    vaultRouter,
    collateralToken: usdc,
    vault,
    vaultReward,
    initLP,
    setMarketLP,
    rewardDistributor,
  };
}

module.exports = {
  deployAll,
};
