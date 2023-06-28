const {
    deployOrConnect2, handleTx, grantRoleIfNotGranted, deployContract,
    isLocalHost
} = require("../utils/helpers");

async function deployMarket({
    deploy = deployOrConnect2,
    marketFactory,
    priceFeed,
    orderMgr,
    positionAddMgr,
    positionSubMgr,
    indexToken,
    feeRouter,
    marketRouter,
    vaultRouter,
    collateralToken,
    globalValid,
    name = "ETH/USD",
    _minSlippage = 1,
    _maxSlippage = 500,
    _minLeverage = 2,
    _maxLeverage = 200,
    _maxTradeAmount = 100000,
    _minPay = 10,
    _minCollateral = 5,
    _allowOpen = true,
    _allowClose = true,
    _tokenDigits = 18,
} = {}) {
    if (marketFactory == null) marketFactory = await deploy("MarketFactory", []);

    if (marketRouter == null)
        marketRouter = await deploy("MarketRouter", [marketFactory.address]);

    if (priceFeed == null) priceFeed = await deploy("MockOracle", []);

    if (positionAddMgr == null)
        positionAddMgr = await deploy("PositionAddMgr", []);

    if (globalValid == null) globalValid = await deploy("GlobalValid", []);

    if (positionSubMgr == null)
        positionSubMgr = await deploy("PositionSubMgr", []);

    if (vaultRouter == null) vaultRouter = await deploy("VaultRouter", []);

    if (collateralToken == null) collateralToken = await deploy("USDC", []);

    if (feeRouter == null) feeRouter = await deploy("FeeRouter", []);

    if (orderMgr == null) orderMgr = await deploy("OrderMgr", []);

    let market = await deploy(name, "Market", [marketFactory.address]);

    const positionBook = await deploy(name, "PositionBook", [
        marketFactory.address,
    ]);
    const orderBookLong = await deploy(
        name,
        "OrderBook",
        [marketFactory.address],
        "orderBookLong"
    );
    const orderBookShort = await deploy(
        name,
        "OrderBook",
        [marketFactory.address],
        "orderBookShort"
    );
    const marketValid = await deploy(name, "MarketValid", [
        marketFactory.address,
    ]);

    await grantRoleIfNotGranted(
        marketValid,
        "MARKET_MGR_ROLE",
        marketFactory.address,
        "marketValid.grant.marketFactory"
    );

    await grantRoleIfNotGranted(
        marketRouter,
        "MARKET_MGR_ROLE",
        marketFactory.address,
        "marketRouter.grant.marketFactory"
    );

    let osl = [];
    for (let index = 0; index < 4; index++) {
        const os = await deploy(
            name,
            "OrderStore",
            [marketFactory.address],
            "OrderStore" + index
        );
        osl.push(os);
    }
    // console.log(collateralToken.address);

    const createInputs = {
        _name: name,
        _marketAddress: market.address, // Enter market address here
        addrs: [
            positionBook.address, //0
            orderBookLong.address, //1
            orderBookShort.address, //2
            marketValid.address, //3
            priceFeed.address, //4
            positionSubMgr.address, //5
            positionAddMgr.address, //6
            indexToken.address, //7
            feeRouter.address, //8
            marketRouter.address, //9
            vaultRouter.address, //10
            collateralToken.address, //11
            globalValid.address, //12
            orderMgr.address, //13
        ], // Enter array of addresses here
        _openStoreLong: osl[0].address, // Enter open store long address here
        _closeStoreLong: osl[1].address, // Enter close store long address here
        _openStoreShort: osl[2].address, // Enter open store short address here
        _closeStoreShort: osl[3].address, // Enter close store short address here
        _minSlippage: _minSlippage,
        _maxSlippage: _maxSlippage,
        _minLeverage: _minLeverage,
        _maxLeverage: _maxLeverage,
        _maxTradeAmount: _maxTradeAmount,
        _minPay: _minPay,
        _minCollateral: _minCollateral,
        _allowOpen: _allowOpen,
        _allowClose: _allowClose,
        _tokenDigits: _tokenDigits,
    };

    console.log(createInputs);

    const [wallet, user0, user1] = await ethers.getSigners();
    console.log(marketFactory.address);
    console.log(wallet.address);
    await grantRoleIfNotGranted(
        marketFactory,
        "MARKET_MGR_ROLE",
        wallet.address,
        "marketFactory.grant.wallet"
    );
    await handleTx(marketFactory.create(createInputs), "marFac.create");
    // await handleTx(marketFactory.marketAskForControllerRole(
    //     [vaultRouter.address, feeRouter.address], market.address
    // ), "marketAskForControllerRole")
    await grantRoleIfNotGranted(
        feeRouter,
        "ROLE_CONTROLLER",
        market.address,
        "feeRouter.grant.market"
    );

    await grantRoleIfNotGranted(
        feeRouter,
        "MARKET_MGR_ROLE",
        wallet.address,
        "feeRouter.grant.wallet"
    );

    await grantRoleIfNotGranted(
        vaultRouter,
        "VAULT_MGR_ROLE",
        wallet.address,
        "vaultRouter.grant.wallet"
    );

    await grantRoleIfNotGranted(
        globalValid,
        "GLOBAL_MGR_ROLE",
        wallet.address,
        "globalValid.grant.wallet"
    );

    return {
        market: market,
        positionBook: positionBook,
        orderBookLong: orderBookLong,
        orderBookShort: orderBookShort,
        marketValid: marketValid,
        osl: osl,
    };
}

module.exports = {
    deployMarket,
};
