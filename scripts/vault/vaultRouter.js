const {
  deployOrConnect,
  readDeployedContract,
  handleTx,
  grantRoleIfNotGranted,
  writeContractAddresses,
  deployUpgradeable,
  getContractAt
} = require("../utils/helpers");

async function deployVaultRouter(writeJson = true) {
  const { implementation, proxy } = await deployUpgradeable("VaultRouter", "VaultRouter")
  const result = {
    VaultRouter: proxy.address,
    ["VaultRouterImpl"]: implementation.address,
  };
  if (writeJson) writeContractAddresses(result);

  return getContractAt("VaultRouter", proxy.address)
}

async function readVaultRouterContract() {
  const vaultRouter = await readDeployedContract("VaultRouter");
  return vaultRouter;
}

async function initialize(coreVaultAddr, feeRouterAddr) {
  const vaultRouter = await readVaultRouterContract();
  await handleTx(
    vaultRouter.initialize(coreVaultAddr, feeRouterAddr),
    "vaultRouter.initialize"
  );
}

async function initializeVaultRouter(coreVaultAddr, feeRouterAddr, vaultRouter = null) {
  if (null == vaultRouter) vaultRouter = await readVaultRouterContract();
  await handleTx(
    vaultRouter.initialize(coreVaultAddr, feeRouterAddr),
    "vaultRouter.initialize"
  );
}

async function setIsFreeze(isFreeze) {
  const vaultRouter = await readVaultRouterContract();
  await handleTx(vaultRouter.setIsFreeze(isFreeze), "vaultRouter.setIsFreeze");
}

async function setMarket(marketAddr, vaultAddr) {
  const vaultRouter = await readVaultRouterContract();
  await handleTx(
    vaultRouter.setMarket(marketAddr, vaultAddr),
    "vaultRouter.setMarket"
  );
  await grantRoleIfNotGranted(
    vaultRouter,
    "ROLE_CONTROLLER",
    market,
    "feeRouter.grant.market"
  );
}

async function removeMarket(marketAddr) {
  const vaultRouter = await readVaultRouterContract();
  await handleTx(
    vaultRouter.removeMarket(marketAddr),
    "vaultRouter.removeMarket"
  );
}

async function transferToVault(account, amount) {
  const vaultRouter = await readVaultRouterContract();
  await handleTx(
    vaultRouter.transferToVault(account, amount),
    "vaultRouter.transferToVault"
  );
}

async function transferFromVault(toAccount, account) {
  const vaultRouter = await readVaultRouterContract();
  await handleTx(
    vaultRouter.transferFromVault(toAccount, account),
    "vaultRouter.transferFromVault"
  );
}

async function borrowFromVault(amount) {
  const vaultRouter = await readVaultRouterContract();
  await handleTx(
    vaultRouter.borrowFromVault(amount),
    "vaultRouter.borrowFromVault"
  );
}

async function repayToVault(amount) {
  const vaultRouter = await readVaultRouterContract();
  await handleTx(vaultRouter.repayToVault(amount), "vaultRouter.repayToVault");
}

async function getUSDBalance() {
  const vaultRouter = await readVaultRouterContract();
  return await vaultRouter.getUSDBalance();
}

async function getGlobalPnl() {
  const vaultRouter = await readVaultRouterContract();
  return await vaultRouter.getGlobalPnl();
}

async function getAUM() {
  const vaultRouter = await readVaultRouterContract();
  return await vaultRouter.getAUM();
}

async function priceDecimals() {
  const vaultRouter = await readVaultRouterContract();
  return await vaultRouter.priceDecimals();
}

async function sellLpFee(vaultAddr) {
  const vaultRouter = await readVaultRouterContract();
  return await vaultRouter.sellLpFee(vaultAddr);
}

async function buyLpFee(vaultAddr) {
  const vaultRouter = await readVaultRouterContract();
  return await vaultRouter.buyLpFee(vaultAddr);
}

module.exports = {
  deployVaultRouter,
  readVaultRouterContract,
  initialize,
  setIsFreeze,
  setMarket,
  removeMarket,
  transferToVault,
  transferFromVault,
  borrowFromVault,
  repayToVault,
  getUSDBalance,
  getGlobalPnl,
  getAUM,
  priceDecimals,
  sellLpFee,
  buyLpFee,
  initializeVaultRouter
};
