const fs = require("fs")
const { ethers } = require("hardhat")
const path = require("path")
const { utils } = require("ethers")

const network = process.env.HARDHAT_NETWORK || "local-dev"
const isLocalFlow = network == "local-dev" ? true : false

let contract_deploy_wait_list = []
let totalGasUsed = 0

function deleteAddressJson() {
  try {
    fs.unlinkSync(contractAddressesFilepath)
  } catch (error) { }
}

function isLocalHost() {
  const network = process.env.HARDHAT_NETWORK || "local-dev"
  return network == "localhost" || network == "local-dev"
}

async function deployContract(name, args = [], label, options) {
  if (!options && typeof label === "object") {
    label = null
    options = label
  }

  let info = name
  if (label) {
    info = name + ":" + label
  }
  const contractFactory = await ethers.getContractFactory(name)
  let contract
  if (options) {
    contract = await contractFactory.deploy(...args, options)
  } else {
    contract = await contractFactory.deploy(...args)
  }
  const argStr = args.map((i) => `"${i}"`).join(" ")
  console.info(`Deploying ${info} ${contract.address} ${argStr}`)
  await contract.deployTransaction.wait()
  console.info("... Completed!")
  return contract
}

async function readDeployedContract(name, args = [], label) {
  let info = name

  let existingObj = readContractAddresses()
  if (label) {
    contractAddress = existingObj[label]
  } else {
    contractAddress = existingObj[info]
  }
  const contractFactory = await ethers.getContractFactory(name)
  return await contractFactory.attach(contractAddress)
}

async function deployWithAddressStorage(name, args = [], label, options) {
  let existingObj = readContractAddresses()
  let isDeployed = false
  let contractAddress
  let keyInfo

  let info = name

  if (label) {
    info = name + ":" + label
    keyInfo = label
    contractAddress = existingObj[label]
    if (contractAddress === undefined) {
      isDeployed = true
    }
  } else {
    keyInfo = info
    contractAddress = existingObj[info]
    if (contractAddress === undefined) {
      isDeployed = true
    }
  }

  const contractFactory = await ethers.getContractFactory(name)
  console.log("%s not exists, deploying.....", keyInfo)

  let contract
  if (options) {
    try {
      contract = await contractFactory.deploy(...args, options)
    } catch (error) {
      console.error("deploy %s failed, error: %s", info, error.message)
      return
    }
  } else {
    try {
      contract = await contractFactory.deploy(...args)
    } catch (error) {
      console.error("deploy %s failed, error: %s", info, error.message)
      return
    }
  }
  const argStr = args.map((i) => `"${i}"`).join(" ")
  console.info(`Deploying ${info} ${contract.address} ${argStr}`)
  // console.info(`Deploying ${info}: ${contract.address} `);
  const receipt = await contract.deployTransaction.wait()
  if (receipt.status === 1) {
    console.log(
      `${keyInfo} deploy success, txHash: %s, gasUsed: %s, total gasUsed: %s`,
      receipt.transactionHash,
      receipt.gasUsed,
      (totalGasUsed += Number(receipt.gasUsed))
    )
  } else {
    console.error(`${keyInfo} deploy failed, receipt: %s`, receipt)
  }
  /*
    await hre.tenderly.persistArtifacts({
      name: "Greeter",
      address: greeter.address,
    })
  */

  let obj = {}
  if (label) {
    obj[label] = contract.address
  } else {
    obj[info] = contract.address
  }
  writeContractAddresses(obj)

  console.info("%s... Completed!", keyInfo)
  return contract
}

async function uploadToTenderfly(name, contract) {
  await hre.tenderly.persistArtifacts({
    name: name,
    address: contract.address,
  })
  // Verify contract on Tenderly
  await hre.tenderly.verify({
    name: name,
    address: contract.address,
  })
}

async function deployOrConnect(
  name,
  args = [],
  label,
  options,
  shouldLog = true
) {
  let existingObj = readContractAddresses()
  let deployed = true
  let contractAddress
  let keyInfo
  let info = name

  if (label) {
    info = name + ":" + label
    keyInfo = label
    contractAddress = existingObj[label]
    if (contractAddress === undefined) {
      deployed = false
    }
  } else {
    keyInfo = info
    contractAddress = existingObj[info]
    if (contractAddress === undefined) {
      deployed = false
    }
  }

  const contractFactory = await ethers.getContractFactory(name)

  if (!isLocalFlow && deployed) {
    // await hre.tenderly.persistArtifacts({
    //   name: name,
    //   address: contractAddress
    // });
    // // Verify contract on Tenderly
    // await hre.tenderly.verify({
    //   name: name,
    //   address: contractAddress,
    // })
    if (shouldLog)
      console.log("%s already exists, address: %s", keyInfo, contractAddress)
    return await contractFactory.attach(contractAddress)
  }

  if (shouldLog) console.log("%s not exists, deploying.....", keyInfo)

  let contract
  if (options) {
    try {
      contract = await contractFactory.deploy(...args, options)
    } catch (error) {
      if (shouldLog)
        console.error("deploy %s failed, error: %s", info, error.message)
      process.exit()
      return
    }
  } else {
    try {
      contract = await contractFactory.deploy(...args)
    } catch (error) {
      if (shouldLog)
        console.error("deploy %s failed, error: %s", info, error.message)
      process.exit()
      return
    }
  }

  // const argStr = args.map((i) => `"${i}"`).join(" ")
  // console.info(`Deploying ${info} ${contract.address} ${argStr}`);
  const receipt = await contract.deployTransaction.wait()
  if (receipt.status === 1) {
    // deploy success
    // ==============================================
    // ADD TO TENDERLY FOR VERIFICATION AND PERSISTENCE
    // ==============================================
    let uploadToTenderfly = false
    try {
      uploadToTenderfly = process.env.UseTenderly == "True"
    } catch (error) { }
    // Check if the deployment is not local and not skipped, and if the UseTenderly environment variable is set to "True"
    if (!isLocalHost() && uploadToTenderfly) {
      // Persist contract artifacts on Tenderly
      await hre.tenderly.persistArtifacts({
        name: name,
        address: contract.address,
      })
      // Verify contract on Tenderly
      await hre.tenderly.verify({
        name: name,
        address: contract.address,
      })
    }
    // ==============================================
    if (shouldLog) {
      console.log(
        // `${keyInfo} deploy success, txHash: %s, gasUsed: %s, total gasUsed: %s`,
        receipt.transactionHash,
        receipt.gasUsed,
        (totalGasUsed += Number(receipt.gasUsed))
      )
    }
  } else {
    // deploy fail
    if (shouldLog)
      console.error(`${keyInfo} deploy failed, receipt: %s`, receipt)
  }

  let obj = {}
  if (label) {
    obj[label] = contract.address
  } else {
    obj[info] = contract.address
  }
  writeContractAddresses(obj)

  if (shouldLog)
    console.info("%s... Completed! address: %s", keyInfo, contract.address)
  return contract
}

async function deployOrConnect2(
  symbol,
  name,
  args = [],
  label,
  options,
  shouldLog = true
) {
  let existingObj = readContractAddresses2(symbol)
  let deployed = true
  let contractAddress
  let keyInfo
  let info = name

  if (label) {
    info = name + ":" + label
    keyInfo = label
    contractAddress = existingObj[label]
    if (contractAddress === undefined) {
      deployed = false
    }
  } else {
    keyInfo = info
    contractAddress = existingObj[info]
    if (contractAddress === undefined) {
      deployed = false
    }
  }

  const contractFactory = await ethers.getContractFactory(name)

  if (!isLocalFlow && deployed) {
    // await hre.tenderly.persistArtifacts({
    //   name: name,
    //   address: contractAddress
    // });
    // // Verify contract on Tenderly
    // await hre.tenderly.verify({
    //   name: name,
    //   address: contractAddress,
    // })
    if (shouldLog)
      console.log("%s already exists, address: %s", keyInfo, contractAddress)
    return await contractFactory.attach(contractAddress)
  }

  if (shouldLog) console.log("%s not exists, deploying.....", keyInfo)

  let contract
  if (options) {
    try {
      contract = await contractFactory.deploy(...args, options)
    } catch (error) {
      if (shouldLog)
        console.error("deploy %s failed, error: %s", info, error.message)
      process.exit()
      return
    }
  } else {
    try {
      contract = await contractFactory.deploy(...args)
    } catch (error) {
      if (shouldLog)
        console.error("deploy %s failed, error: %s", info, error.message)
      process.exit()
      return
    }
  }

  // const argStr = args.map((i) => `"${i}"`).join(" ")
  // console.info(`Deploying ${info} ${contract.address} ${argStr}`);
  const receipt = await contract.deployTransaction.wait()
  if (receipt.status === 1) {
    // deploy success
    // ==============================================
    // ADD TO TENDERLY FOR VERIFICATION AND PERSISTENCE
    // ==============================================
    let uploadToTenderfly = false
    try {
      uploadToTenderfly = process.env.UseTenderly == "True"
    } catch (error) { }
    // Check if the deployment is not local and not skipped, and if the UseTenderly environment variable is set to "True"
    if (!isLocalHost() && uploadToTenderfly) {
      // Persist contract artifacts on Tenderly
      await hre.tenderly.persistArtifacts({
        name: name,
        address: contract.address,
      })
      // Verify contract on Tenderly
      await hre.tenderly.verify({
        name: name,
        address: contract.address,
      })
    }
    // ==============================================
    if (shouldLog) {
      console.log(
        // `${keyInfo} deploy success, txHash: %s, gasUsed: %s, total gasUsed: %s`,
        receipt.transactionHash,
        receipt.gasUsed,
        (totalGasUsed += Number(receipt.gasUsed))
      )
    }
  } else {
    // deploy fail
    if (shouldLog)
      console.error(`${keyInfo} deploy failed, receipt: %s`, receipt)
  }

  let obj = {}
  if (label) {
    obj[label] = contract.address
  } else {
    obj[info] = contract.address
  }
  writeContractAddresses2(obj, symbol)

  if (shouldLog)
    console.info("%s... Completed! address: %s", keyInfo, contract.address)
  return contract
}

async function handleTx(txPromise, label) {
  let promiseInfo = label ? label : "contract function"
  let index = 0
  const RETRY_ATTEPMTS = 1
  for (index = 0; index < RETRY_ATTEPMTS; index++) {
    try {
      await txPromise.then(
        async (pendingTx) => {
          console.log(`${promiseInfo} executing, waiting for confirm...`)
          const receipt = await pendingTx.wait()
          if (receipt.status === 1) {
            console.log(
              `${promiseInfo} executing success, txHash: %s, gasUsed: %s, total gasUsed: %s`,
              receipt.transactionHash,
              receipt.gasUsed,
              (totalGasUsed += Number(receipt.gasUsed))
            )
            index = 100
          } else {
            console.error(
              `${promiseInfo} executing failed, receipt: %s`,
              receipt
            )
          }
        },
        (error) => {
          console.error(
            "failed to execute transaction: %s, error: %s",
            promiseInfo,
            error
          )
        }
      )
    } catch (error) {
      console.log(error)
      console.log("retry", index + 1)
    }
  }
}

async function waitTx(txPromise, label) {
  await txPromise.then(
    async (pendingTx) => {
      console.log(`${label} executing, waiting for confirm...`)
      const receipt = await pendingTx.wait()
      if (receipt.status === 1) {
      } else {
        process.exit()
      }
    },
    (error) => {
      console.error(`failed to execute transaction ${label} , error: ${error}`)
      process.exit()
    }
  )
}

async function contractAt(name, address, provider) {
  let contractFactory = await ethers.getContractFactory(name)
  if (provider) {
    contractFactory = await contractFactory.connect(provider)
  }
  return await contractFactory.attach(address)
}

// 针对的是这个函数的文件目录？
const contractAddressesFilepath = path.join(
  __dirname,
  "../..",
  `contract-addresses-${network}.json`
)
function getAddress(symbol) {
  const firstThree = symbol.substring(0, 3)
  const tempPath = path.join(
    __dirname,
    "../..",
    `contract-addresses-${network}-${firstThree}.json`
  )
  return tempPath
}

function readContractAddresses() {
  if (fs.existsSync(contractAddressesFilepath)) {
    return JSON.parse(fs.readFileSync(contractAddressesFilepath))
  }
  return {}
}

function readContractAddresses2(symol) {
  const tempPath = getAddress(symol)
  if (fs.existsSync(tempPath)) {
    return JSON.parse(fs.readFileSync(tempPath))
  }
  return {}
}

function writeContractAddresses(json) {
  const tmpAddresses = Object.assign(readContractAddresses(), json)
  fs.writeFileSync(contractAddressesFilepath, JSON.stringify(tmpAddresses))
}

function writeContractAddresses2(json, symbol) {
  const tmpAddresses = Object.assign(readContractAddresses2(symbol), json)
  const contractAddressesFilepath = getAddress(symbol)
  fs.writeFileSync(contractAddressesFilepath, JSON.stringify(tmpAddresses))
}

async function callWithRetries(func, args, retriesCount = 3) {
  let i = 0
  while (true) {
    i++
    try {
      return await func(...args)
    } catch (ex) {
      if (i === retriesCount) {
        console.error("call failed %s times. throwing error", retriesCount)
        throw ex
      }
      console.error("call i=%s failed. retrying....", i)
      console.error(ex.message)
    }
  }
}

// batchLists is an array of lists
async function processBatch(batchLists, batchSize, handler) {
  let currentBatch = []
  const referenceList = batchLists[0]

  for (let i = 0; i < referenceList.length; i++) {
    const item = []

    for (let j = 0; j < batchLists.length; j++) {
      const list = batchLists[j]
      item.push(list[i])
    }

    currentBatch.push(item)

    if (currentBatch.length === batchSize) {
      console.log(
        "handling currentBatch",
        i,
        currentBatch.length,
        referenceList.length
      )
      await handler(currentBatch)
      currentBatch = []
    }
  }

  if (currentBatch.length > 0) {
    console.log(
      "handling final batch",
      currentBatch.length,
      referenceList.length
    )
    await handler(currentBatch)
  }
}

function copyJsonFiles(sourceFolder, destFolder) {
  // Get a list of files in the source folder
  const files = fs.readdirSync(sourceFolder)
  // Loop through each file
  files.forEach((file) => {
    const filePath = path.join(sourceFolder, file)
    const stats = fs.statSync(filePath)

    // If the file is a directory, recursively call the function
    if (stats.isDirectory()) {
      // console.log(filePath);
      // console.log(path.join(destFolder, file));
      copyJsonFiles(filePath, destFolder)
    } else {
      // If the file is a JSON file, copy it to the destination folder
      if (path.extname(filePath) === ".json" && file.indexOf(".dbg.") == -1) {
        const fileContents = fs.readFileSync(filePath)
        const destPath = path.join(destFolder, file)
        fs.writeFileSync(destPath, fileContents)
      }
    }
  })
}

function copyAbis2() {
  const paths = [
    "../../artifacts/contracts/market/MarketRouter.sol/MarketRouter.json",
    "../../artifacts/contracts/market/MarketReader.sol/MarketReader.json",
    "../../artifacts/contracts/vault/VaultRouter.sol/VaultRouter.json",
    "../../artifacts/contracts/vault/VaultReward.sol/VaultReward.json",
  ]
  for (let index = 0; index < paths.length; index++) {
    const sourceFile = path.join(__dirname, paths[index])
    const ppp = sourceFile.split("/")
    const fileName = ppp[ppp.length - 1]
    const destFolder = path.join(
      __dirname,
      "./../../../depx-view/src/abis/" + fileName
    )
    console.log(destFolder)
    const fileContents = fs.readFileSync(sourceFile)
    fs.writeFileSync(destFolder, fileContents)
  }
}

function copyAddressJson() {
  const f = "contract-addresses-avalancheTest.json"
  const file = path.join(__dirname, "../..", f)
  const destFolder = path.join(
    __dirname,
    "./../../../depx-view/src/config/address/"
  )
  const fileContents = fs.readFileSync(file)
  const destPath = path.join(destFolder, f)
  fs.writeFileSync(destPath, fileContents)
}

function copyAddressLocalDev() {
  const f = "contract-addresses-localhost.json"
  const file = path.join(__dirname, "../..", f)
  const destFolder = path.join(
    __dirname,
    "./../../../depx-view/src/config/address/"
  )
  const fileContents = fs.readFileSync(file)
  const destPath = path.join(destFolder, f)
  fs.writeFileSync(destPath, fileContents)
}
async function sendTxn(txnPromise, label) {
  const txn = await txnPromise
  console.info(`Sending ${label}...`)
  await txn.wait()
  console.info(`... Sent! ${txn.hash}`)
  await sleep(2000)
  return txn
}
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

async function grantRoleIfNotGranted(granter, role, grantee, label) {
  const roleHash = utils.keccak256(utils.toUtf8Bytes(role))

  if (await granter.hasRole(roleHash, grantee)) {
    console.log("granted", label)
    return
  }

  await handleTx(granter.grantRole(roleHash, grantee), label)
}

async function revokeRoleIfGranted(granter, role, grantee, label) {
  const roleHash = utils.keccak256(utils.toUtf8Bytes(role))

  if (isLocalFlow) {
    return await handleTx(granter.revokeRole(roleHash, grantee), label)
  }

  if (await granter.hasRole(roleHash, grantee)) {
    await handleTx(granter.revokeRole(roleHash, grantee), label)
    console.log("revokeRole", label)
    return
  }
}

module.exports = {
  deployContract,
  deployOrConnect,
  contractAt,
  writeContractAddresses,
  readContractAddresses,
  callWithRetries,
  processBatch,
  handleTx,
  contract_deploy_wait_list,
  readDeployedContract,
  isLocalFlow,
  copyAbis2,
  copyAddressJson,
  copyAddressLocalDev,
  sendTxn,
  grantRoleIfNotGranted,
  revokeRoleIfGranted,
  deleteAddressJson,
  deployWithAddressStorage,
  uploadToTenderfly,
  waitTx,
  isLocalHost,
  deployOrConnect2
}
