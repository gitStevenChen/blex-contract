const { deployOrConnect, writeContractAddresses } = require("../utils/helpers")

async function deployReferral(writeJson) {
  const referral = await deployOrConnect("Referral")

  const result = { 
    Referral: referral.address 
  };
  if (writeJson)
    writeContractAddresses(result)

  return {
    referral: referral,
  }
}

module.exports = {
  deployReferral,
}
