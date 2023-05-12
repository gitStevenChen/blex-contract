const fs = require("fs")
const { ethers } = require("hardhat")
const path = require("path")
const network = process.env.HARDHAT_NETWORK || "local-dev"
const isLocalFlow = network == "local-dev" ? true : false
const hre = require("hardhat");

let contract_deploy_wait_list = []
let totalGasUsed = 0

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

async function uploadToTenderfly(name, contract) {
  await hre.tenderly.persistArtifacts({
    name: name,
    address: contract.address
  });
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
  let notDeployed = false
  let contractAddress
  let keyInfo

  let info = name

  if (label) {
    info = name + ":" + label
    keyInfo = label
    contractAddress = existingObj[label]
    if (contractAddress === undefined) {
      notDeployed = true
    }
  } else {
    keyInfo = info
    contractAddress = existingObj[info]
    if (contractAddress === undefined) {
      notDeployed = true
    }
  }

  const contractFactory = await ethers.getContractFactory(name)

  // if (!isDeployed) {
  if (!isLocalFlow && !notDeployed) {
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
  if (receipt.status === 1) { // deploy success
    // ==============================================
    // ADD TO TENDERLY FOR VERIFICATION AND PERSISTENCE
    // ==============================================
    let uploadToTenderfly = false
    try {
      uploadToTenderfly = process.env.UseTenderly == "True"
    } catch (error) { }
    // Check if the deployment is not local and not skipped, and if the UseTenderly environment variable is set to "True"
    if (!isLocalFlow && uploadToTenderfly) {
      // Persist contract artifacts on Tenderly
      await hre.tenderly.persistArtifacts({
        name: name,
        address: contract.address
      });
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
  } else { // deploy fail
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

  if (shouldLog) console.info("%s... Completed!", keyInfo)
  return contract
}

async function deployOrConnectNoWait(name, args = [], label, options) {
  if (isLocalFlow) {
    return await deployOrConnect(name, args, label, options)
  }
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

  if (!isLocalFlow && !isDeployed) {
    console.log("%s already exists, address: %s", keyInfo, contractAddress)
    return await contractFactory.attach(contractAddress)
  }

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

  return contract
}
async function handleContractListWait(label, provider) {
  console.log(contract_deploy_wait_list.length, " contracts to wait")
  let obj = {}
  for (let index = 0; index < contract_deploy_wait_list.length; index++) {
    let my_obj = contract_deploy_wait_list[index]
    contract = my_obj["contract"]
    label = my_obj["label"]
    info = my_obj["info"]
    keyInfo = my_obj["keyInfo"]

    await contract.deployTransaction.wait()
    if (label) {
      obj[label] = contract.address
    } else {
      obj[info] = contract.address
    }
    console.info("%s... Completed!", keyInfo)
    writeContractAddresses(obj)
  }
  contract_deploy_wait_list = []
}
let grant_role_wait_list = []

async function handleTxListWait() {
  console.log(grant_role_wait_list.length, " tx to wait")

  for (let index = 0; index < grant_role_wait_list.length; index++) {
    let obj = grant_role_wait_list[index]
    let pendingTx = obj["pendingTx"]
    let promiseInfo = obj["promiseInfo"]
    const receipt = await pendingTx.wait()
    if (receipt.status === 1) {
      console.log(
        `${promiseInfo} executing success, txHash: %s`,
        receipt.transactionHash
      )
    } else {
      console.error(`${promiseInfo} executing failed, receipt: %s`, receipt)
    }
  }
  grant_role_wait_list = []
}

async function handleTx(txPromise, label, shouldLog = true) {
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
            if (shouldLog)
              console.log(
                `${promiseInfo} executing success, txHash: %s, gasUsed: %s, total gasUsed: %s`,
                receipt.transactionHash,
                receipt.gasUsed,
                (totalGasUsed += Number(receipt.gasUsed))
              )
            index = 100
          } else {
            if (shouldLog)
              console.error(
                `${promiseInfo} executing failed, receipt: %s`,
                receipt
              )
          }
        },
        (error) => {
          if (shouldLog)
            console.error(
              "failed to execute transaction: %s, error: %s",
              promiseInfo,
              error
            )
        }
      )
    } catch (error) {
      if (shouldLog) console.log(error)
      if (shouldLog) console.log("retry", index + 1)
    }
  }
}
async function handleTxNoWait(txPromise, label, provider) {
  if (isLocalFlow) {
    return await handleTx(txPromise, label, provider)
  }
  let promiseInfo = label ? label : "contract function"
  await txPromise.then(
    async (pendingTx) => {
      if (provider) {
        const { gasUsed } = await provider.getTransactionReceipt(pendingTx.hash)
        console.info(label, gasUsed.toString())
      }
      console.log(`${promiseInfo} executing, waiting for confirm...`)

      grant_role_wait_list.push({
        pendingTx: pendingTx,
        promiseInfo: promiseInfo,
      })
    },
    (error) => {
      console.error(
        "failed to execute transaction: %s, error: %s",
        promiseInfo,
        error
      )
    }
  )
}

async function handleTxUnitTest(txPromise, label, provider) {
  let promiseInfo = label ? label : "contract function"
  await txPromise.then(
    async (pendingTx) => {
      if (provider) {
        const { gasUsed } = await provider.getTransactionReceipt(pendingTx.hash)
        console.info(label, gasUsed.toString())
      }
      const receipt = await pendingTx.wait()
      if (receipt.status === 1) {
      } else {
        console.error(`${promiseInfo} executing failed, receipt: %s`, receipt)
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
  "..",
  `contract-addresses-${network}.json`
)

function readContractAddresses() {
  if (fs.existsSync(contractAddressesFilepath)) {
    return JSON.parse(fs.readFileSync(contractAddressesFilepath))
  }
  return {}
}

function writeContractAddresses(json) {
  const tmpAddresses = Object.assign(readContractAddresses(), json)
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
  const sourceFolder = path.join(__dirname, "../artifacts")
  const destFolder = path.join(__dirname, "./../../depx-view/src/abis/")
  copyJsonFiles(sourceFolder, destFolder)
}

function copyAddressJson() {
  const f = "contract-addresses-avalancheTest.json"
  const file = path.join(__dirname, "..", f)
  const destFolder = path.join(
    __dirname,
    "./../../depx-view/src/config/address/"
  )
  const fileContents = fs.readFileSync(file)
  const destPath = path.join(destFolder, f)
  fs.writeFileSync(destPath, fileContents)
}

function copyAddressLocalDev() {
  const f = "contract-addresses-localhost.json"
  const file = path.join(__dirname, "..", f)
  const destFolder = path.join(
    __dirname,
    "./../../depx-view/src/config/address/"
  )
  const fileContents = fs.readFileSync(file)
  const destPath = path.join(destFolder, f)
  fs.writeFileSync(destPath, fileContents)
}

module.exports = {
  deployOrConnect,
  contractAt,
  writeContractAddresses,
  readContractAddresses,
  callWithRetries,
  processBatch,
  handleTx,
  handleTxUnitTest,
  handleContractListWait,
  contract_deploy_wait_list,
  deployOrConnectNoWait,
  handleTxNoWait,
  readDeployedContract,
  handleTxListWait,
  isLocalFlow,
  copyAbis2,
  copyAddressJson,
  copyAddressLocalDev,
  uploadToTenderfly
}
