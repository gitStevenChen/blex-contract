const {
  getContractAt,
  readUpgradableDeployedContract,
  handleTx,
  writeContractAddresses,
  deployUpgradeable
} = require("../utils/helpers");

async function deployCoreVault(writeJson = true) {

  const { implementation, proxy } = await deployUpgradeable("CoreVault", "CoreVault")
  const result = {
    CoreVault: proxy.address,
    ["CoreVaultImpl"]: implementation.address,
  };
  if (writeJson) writeContractAddresses(result);

  return getContractAt("CoreVault", proxy.address)
}

async function readCoreVaultContract() {
  const vault = await readUpgradableDeployedContract("CoreVault");
  return vault;
}

async function initCoreVault({ coreVault, asset, name, symbol, vaultRouterAddr, feeRouterAddr }) {
  if (null == coreVault) coreVault = await readCoreVaultContract();
  await handleTx(
    coreVault.initialize(asset, name, symbol, vaultRouterAddr, feeRouterAddr),
    "coreVault.initialize"
  );
}

async function setVaultRouter(vaultRouterAddr) {
  const vault = await readCoreVaultContract();
  await handleTx(
    vault.setVaultRouter(vaultRouterAddr),
    "coreVault.setVaultRouter"
  );
}

async function setLpFee(isBuy, fee) {
  const vault = await readCoreVaultContract();
  await handleTx(vault.setLpFee(isBuy, fee), "coreVault.setLpFee");
}

async function setCooldownDuration(duration) {
  const vault = await readCoreVaultContract();
  await handleTx(
    vault.setCooldownDuration(duration),
    "coreVault.setCooldownDuration"
  );
}

async function setIsFreeze(isFreeze) {
  const vault = await readCoreVaultContract();
  await handleTx(vault.setIsFreeze(isFreeze), "coreVault.setIsFreeze");
}

async function transferOutAssets(toAddress, amount) {
  const vault = await readCoreVaultContract();
  await handleTx(
    vault.transferOutAssets(toAddress, amount),
    "coreVault.transferOutAssets"
  );
}

async function computationalCosts(isBuy, amount) {
  const vault = await readCoreVaultContract();
  const cost = await vault.computationalCosts(isBuy, amount);
  return cost;
}

async function verifyOutAssets(toAddress, amount) {
  const vault = await readCoreVaultContract();
  const isOk = await vault.verifyOutAssets(toAddress, amount);
  return isOk;
}

async function getTotalAssets() {
  const vault = await readCoreVaultContract();
  const amount = await vault.totalAssets();
  return amount;
}

async function getLPFee(isBuy) {
  const vault = await readCoreVaultContract();
  const fee = await vault.getLPFee(isBuy);
  return fee;
}

module.exports = {
  deployCoreVault,
  readCoreVaultContract,
  initCoreVault,
  setVaultRouter,
  setLpFee,
  setCooldownDuration,
  setIsFreeze,
  transferOutAssets,
  computationalCosts,
  verifyOutAssets,
  getTotalAssets,
  getLPFee,
};
