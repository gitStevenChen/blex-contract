# Blex.io Perpetual Trading Platform   

Blex.io is a decentralized Perpetual Trading platform built on Ethereum blockchain technology. The platform allows users to trade various crypto derivative products. Its goal is to provide users with an efficient, low-cost, secure, and reliable trading environment.

## Key Features

The main features of the Blex.io Perpetual Trading Platform are:

- **Decentralized**: The Blex.io platform is built on the Ethereum blockchain and has no central authority controlling it. This means that trades are transparent and secure, and not subject to the control of any single entity.
- **Efficient**: The Blex.io platform uses smart contracts to execute trades, reducing transaction costs and time while ensuring their security and accuracy.
- **Low cost**: Due to the decentralized nature of the platform, Blex.io avoids the costs of intermediaries and significantly reduces transaction costs.
- **Diversity**: Blex.io supports a range of option trading products, including futures, options, and swaps, meeting the different investment needs of users.

## Smart Contracts

The core smart contract of the Blex.io trading platform is the **Market** contract, which is responsible for creating and managing derivatives, processing trade orders, and settling trades. 

In addition to the **Market** contract, there are also the following contracts:

- **CoreVault**: The core vault contract manages funds for liquidity providers using the ERC4626 standard.
- **FastPriceFeed**: The price feed contract securely obtains on-chain asset prices and provides them to traders.
- **FeeVault**: The fee vault contract manages all fees for the platform.
- **RewardDistributor**: The reward contract manages platform fees and rewards liquidity providers and other participants in the platform.

The **MarketRouter** contract interacts with these contracts to enable trading activities on the platform, becoming a key component of the Blex.io options trading ecosystem.

## Contract Deployment and Testing

To deploy and test the Blex.io Perpetual Trading Platform, you can use the following script. In the project's root directory, run the following commands:

    yarn install # Install all dependencies
    yarn localnode # Run a local node
    yarn local # Deploy the smart contracts to the local test node
    yarn test # Run unit tests for the smart contracts·

Before deploying and testing, make sure you have Node.js and Truffle framework installed locally.

## Copyright

The Blex.io Perpetual Trading Platform is an open-source project following the MIT license.
