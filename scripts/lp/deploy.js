const {
  deployOrConnect,
  waitTx,
  grantRoleIfNotGranted,
} = require("../utils/helpers")
const { deployCoreVault, initCoreVault } = require("../vault/coreVault")
const {
  initializeVaultReward,
  deployVaultReward
} = require("../vault/vaultReward")
const {
  initializeVaultRouter,
  deployVaultRouter,
} = require("../vault/vaultRouter")

const { utils } = require("ethers")


async function deployAll(usdc, isInit = true) {
  const vault = await deployCoreVault()
  const vaultRouter = await deployVaultRouter()
  const vaultReward = await deployVaultReward()
  const rewardDistributor = await deployOrConnect("RewardDistributor")

  const setMarketLP = ({ market, vault } = {}) => {
    return waitTx(
      vaultRouter.setMarket(market.address, vault.address),
      "setMarket"
    )
  }

  const initLP = async ({
    USDC,
    name,
    symbol,
    vault,
    vaultRouter,
    vaultReward,
    feeRouter,
    rewardDistributor
  } = {}) => {

    await initializeVaultRouter(
      vault.address,
      feeRouter.address,
      vaultRouter
    )

    await initializeVaultReward(
      vault.address,
      vaultRouter.address,
      feeRouter.address,
      rewardDistributor.address,
      vaultReward
    )

    await waitTx(
      rewardDistributor.initialize(
        USDC.address,
        vaultReward.address
      ),
      "rewardDistributor.init"
    )

    await initCoreVault({
      coreVault: vault,
      asset: USDC.address,
      name,
      symbol,
      vaultRouterAddr: vaultRouter.address,
      feeRouterAddr: feeRouter.address
    })

    await grantRoleIfNotGranted(vault, "ROLE_CONTROLLER", vaultReward.address)
    await grantRoleIfNotGranted(vault, "ROLE_CONTROLLER", vaultRouter.address)

  }

  return {
    vaultRouter,
    collateralToken: usdc,
    vault,
    vaultReward,
    initLP,
    setMarketLP,
    rewardDistributor
  }
}

module.exports = {
  deployAll,
}
