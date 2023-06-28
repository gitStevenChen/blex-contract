const {
  deployOrConnect,
  readDeployedContract,
  handleTx,
  writeContractAddresses,
} = require("../utils/helpers");

async function deployRewardDistributor(writeJson) {
  const distributor = await deployOrConnect("RewardDistributor", []);

  const result = {
    RewardDistributor: distributor.address,
  };
  if (writeJson) writeContractAddresses(result);

  return distributor;
}

async function readRewardDistributorContract() {
  return await readDeployedContract("RewardDistributor");
}

async function initialize(rewardTokenAddr, rewardTrackerAddr) {
  const distributor = await readRewardDistributorContract();
  await handleTx(
    distributor.initialize(rewardTokenAddr, rewardTrackerAddr),
    "rewardDistributor.initialize"
  );
}

async function setTokensPerInterval(amount) {
  const distributor = await readRewardDistributorContract();
  await handleTx(
    distributor.setTokensPerInterval(amount),
    "rewardDistributor.setTokensPerInterval"
  );
}

async function updateLastDistributionTime() {
  const distributor = await readRewardDistributorContract();
  await handleTx(
    distributor.updateLastDistributionTime(),
    "rewardDistributor.updateLastDistributionTime"
  );
}

async function withdrawToken(tokenAddr, toAddress, amount) {
  const distributor = await readRewardDistributorContract();
  await handleTx(
    distributor.withdrawToken(tokenAddr, toAddress, amount),
    "rewardDistributor.withdrawToken"
  );
}

async function distribute() {
  const distributor = await readRewardDistributorContract();
  await handleTx(distributor.distribute(), "rewardDistributor.distribute");
}

async function pendingRewards() {
  const distributor = await readRewardDistributorContract();
  return distributor.pendingRewards();
}

module.exports = {
  deployRewardDistributor,
  readRewardDistributorContract,
  initialize,
  setTokensPerInterval,
  withdrawToken,
  updateLastDistributionTime,
  distribute,
  pendingRewards,
};
