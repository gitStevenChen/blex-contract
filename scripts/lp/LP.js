const { deployOrConnect, handleTx } = require("../utils/helpers")
const { utils } = require("ethers")
const { deployAll } = require("./deploy")
async function main() {
  const [deployer] = await ethers.getSigners()
  console.log("deployer: ", deployer.address)

  const amount = utils.parseUnits("1000", 6)


  const usdc = await deployOrConnect("USDC", ["USDC", "USDC", amount], "USDC")

  const LP = await deployAll(usdc)

  // load status
  const aum = await LP.vaultReward.getAUM()
  const pnl = await LP.vaultRouter.getGlobalPnl()
  const usdBalance = await LP.vaultReward.getUSDBalance()
  const lpSupply = await LP.vault.totalSupply()
  console.log("aum: %s", aum)
  console.log("pnl: %s", pnl)
  console.log("usdBalance: %s", usdBalance)
  console.log("lpSupply: %s", lpSupply)


  return

  const feeRouter = await deployOrConnect("VaultFeeRouter")

  await LP.init(LP.vault, LP.vaultRouter, LP.vaultReward, feeRouter)

  const market = await deployOrConnect("VaultMarket")
  await LP.setMarket(market.address, LP.vault.address)
  await handleTx(usdc.approve(LP.vaultReward.address, amount), "usdc.approve")

  await handleTx(
    LP.vaultReward.buy(LP.vault.address, deployer.address, amount, 0),
    "vaultReward.deposit"
  )
  const vaultBalance = await usdc.balanceOf(LP.vault.address)
  console.log("vaultBalance: ", vaultBalance.toString())

  const shares = await LP.vault.balanceOf(deployer.address)
  console.log("lp shares: ", await LP.vault.balanceOf(deployer.address))
  // console.log("lp assets: ", await LP.vault.totalAssets())

  await handleTx(LP.vault.approve(LP.vaultRouter.address, shares), "LP.approve")
  await handleTx(LP.vault.approve(LP.vaultReward.address, shares), "LP.approve")

  await handleTx(
    LP.vaultReward.sell(LP.vault.address, deployer.address, 100, 0)
    // LP.vaultRouter.sell(LP.vault.address, deployer.address, 100, 0)
  )

  console.log(
    "after sell lp shares: ",
    await LP.vault.balanceOf(deployer.address)
  )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
