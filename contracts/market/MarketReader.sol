// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import {IMarket} from "./interfaces/IMarket.sol";
import {IMarketRouter} from "./interfaces/IMarketRouter.sol";
import {IGlobalValid} from "./interfaces/IGlobalValid.sol";
import "./GlobalDataTypes.sol";
import {IMarketValid} from "./interfaces/IMarketValid.sol";
import {MarketConfigStruct} from "./MarketConfigStruct.sol";
import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import "../vault/interfaces/IVaultRouter.sol";
import {MarketLib} from "./MarketLib.sol";
import {MarketDataTypes} from "./MarketDataTypes.sol";
import "./../position/PositionStruct.sol";
import {IPrice} from "../oracle/interfaces/IPrice.sol";

import "../ac/Ac.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IMarketFactory.sol";
import {TransferHelper} from "./../utils/TransferHelper.sol";
import "./interfaces/IMarketReader.sol";

contract MarketReader is Ac, IMarketReader {
    using MarketConfigStruct for IMarketValid.Props;

    IMarketRouter public marketRouter;
    IVaultRouter public vaultRouter;
    IMarketFactory public fac;

    constructor(address _f) Ac(_f) {
        fac = IMarketFactory(_f);
    }

    function initialize(
        address _marketRouter,
        address _vaultRouter
    ) external onlyOwner initializeLock {
        require(_marketRouter != address(0));
        require(_vaultRouter != address(0));
        marketRouter = IMarketRouter(_marketRouter);
        vaultRouter = IVaultRouter(_vaultRouter);
    }

    /**
     * @dev This function returns an array of market information, including the market name, address, and whether the market allows opening and closing positions.
     * @return _outs An array of structures containing information about each market, including the name, address, and whether opening and closing positions are allowed.
     */
    function getMarkets()
        external
        view
        returns (IMarketFactory.Outs[] memory _outs)
    {
        return fac.getMarkets();
    }

    /**
     * @dev This function checks if an account's position in a market is eligible for liquidation and returns a state code.
     * @param market The address of the market in which the position is held.
     * @param _account The address of the account whose position will be checked for liquidation eligibility.
     * @param _isLong A boolean flag indicating whether the position being checked is a long position.
     * @return _state A uint256 value representing the state code of the liquidation eligibility check.
     */
    function isLiquidate(
        address market,
        address _account,
        bool _isLong
    ) external view returns (uint256 _state) {
        IMarket im = IMarket(market);
        IMarketValid mv = IMarketValid(im.marketValid());
        return
            mv.isLiquidate(
                _account,
                market,
                _isLong,
                im.positionBook(),
                im.feeRouter(),
                IPrice(im.priceFeed()).getPrice(im.indexToken(), !_isLong)
            );
    }

    /**
     * @dev This function returns the current and cumulative funding rates of a market for a specified type of position.
     * @param _market The address of the market for which to retrieve the funding rates.
     * @param _isLong A boolean flag indicating whether the position type for which to retrieve the funding rates is a long position.
     * @return A tuple containing two int256 values: `nowRate` and `totalRate`.
     * `nowRate` is the current funding rate of the market for the specified position type, calculated using the formula provided by the `getFundingRate()` function of the associated `IFeeRouter` contract.
     * `totalRate` is the cumulative funding rate of the market for the specified position type, calculated using the cumulativeFundingRates() function of the associated `IFeeRouter` contract.
     */
    function getFundingRate(
        address _market,
        bool _isLong
    ) external view returns (int256, int256) {
        IFeeRouter fr = IMarket(_market).feeRouter();

        IPositionBook positionBook = IMarket(_market).positionBook();
        (uint256 _longSize, uint256 _shortSize) = positionBook.getMarketSizes();

        int256 nowRate = fr.getFundingRate(
            _market,
            _longSize,
            _shortSize,
            _isLong
        );
        int256 totalRate = fr.cumulativeFundingRates(_market, _isLong);

        return (nowRate, totalRate);
    }

    /**
     * @dev This function calculates the available liquidity for a given account in a market.
     * @param market Address of the market
     * @param account Address of the account for which the available liquidity is to be calculated
     * @param isLong Boolean indicating if the position to be calculated is long or short
     * @return The amount of available liquidity in the market denominated in the collateral token of the market
     */
    function availableLiquidity(
        address market,
        address account,
        bool isLong
    ) external view returns (uint256) {
        IPositionBook positionBook = IMarket(market).positionBook();
        address _globalValid = IMarket(market).globalValid();

        GlobalDataTypes.ValidParams memory _params;

        _params.market = market;
        _params.isLong = isLong;
        _params.sizeDelta = 0;

        (_params.marketLongSizes, _params.marketShortSizes) = positionBook
            .getMarketSizes();
        (_params.userLongSizes, _params.userShortSizes) = marketRouter
            .getAccountSize(account);
        (_params.globalLongSizes, _params.globalShortSizes) = marketRouter
            .getGlobalSize();

        address _collateralToken = IMarket(market).collateralToken();

        _params.usdBalance = TransferHelper.parseVaultAsset(
            vaultRouter.getUSDBalance(),
            IERC20Metadata(_collateralToken).decimals()
        );

        return IGlobalValid(_globalValid).getMaxIncreasePositionSize(_params);
    }

    /**
     * @dev Retrieves information about a market, including its validation parameters, market parameters, and fee parameters.
     * @param _marketAddr Address of the market to retrieve information about.
     * @return validOuts Struct containing the validation parameters for the market.
     * @return mktOuts Struct containing the market parameters, such as token digits, fee rates, and order book and position book addresses.
     * @return feeOuts Struct containing the fee parameters, such as fee rates and fee precision.
     */
    function getMarket(
        address _marketAddr
    )
        external
        view
        returns (
            ValidOuts memory validOuts,
            MarketOuts memory mktOuts,
            FeeOuts memory feeOuts
        )
    {
        IMarket _market = IMarket(_marketAddr);
        IFeeRouter fr = _market.feeRouter();
        address marketValid = _market.marketValid();
        IMarketValid.Props memory _conf = IMarketValid(marketValid).conf();
        validOuts = ValidOuts(
            _conf.getMinSlippage(),
            _conf.getMaxSlippage(),
            calZeros(MarketConfigStruct.DENOMINATOR_SLIPPAGE),
            _conf.getMinLev(),
            _conf.getMaxLev(),
            _conf.getMinCollateral(),
            _conf.getMaxTradeAmount(),
            _conf.getAllowOpen(),
            _conf.getAllowClose()
        );

        mktOuts = MarketOuts(
            uint256(_market.USDDecimals()),
            fr.feeAndRates(_marketAddr, 1), // closeFeeRate
            fr.feeAndRates(_marketAddr, 0), // openFeeRate
            fr.feeAndRates(_marketAddr, 4), // liquidateFee
            0,
            _market.indexToken(),
            _market.collateralToken(),
            address(_market.orderBookLong()),
            address(_market.orderBookShort()),
            address(_market.positionBook())
        );
        feeOuts = FeeOuts(
            fr.feeAndRates(_marketAddr, 1), // closeFeeRate
            fr.feeAndRates(_marketAddr, 0), // openFeeRate
            fr.feeAndRates(_marketAddr, 3), // execFee
            fr.feeAndRates(_marketAddr, 4), // liquidateFee
            calZeros(fr.FEE_RATE_PRECISION())
        );
    }

    /**
     * @dev This function retrieves the positions of a given account in a market or in all markets if market address is not provided
     * @param account Address of the account whose positions are to be retrieved
     * @param market Optional address of the market. If provided, retrieves the positions in the specified market. If not provided, retrieves the positions in all markets
     * @return _positions Array of `Position.Props` structures representing the positions of the account in the specified market or in all markets
     */
    function getPositions(
        address account,
        address market
    ) external view returns (Position.Props[] memory _positions) {
        if (market == address(0)) {
            IMarketFactory.Outs[] memory _outs = fac.getMarkets();
            address _market;
            uint256 _index;
            uint256 _counter;

            for (uint i = 0; i < _outs.length; i++) {
                _market = _outs[i].addr;
                Position.Props[] memory _pos = IMarket(_market).getPositions(
                    account
                );
                _counter += _pos.length;
            }

            if (_counter == 0) {
                return _positions;
            }
            _positions = new Position.Props[](_counter);

            for (uint i = 0; i < _outs.length; i++) {
                _market = _outs[i].addr;
                Position.Props[] memory _pos = IMarket(_market).getPositions(
                    account
                );

                for (uint j = 0; j < _pos.length; j++) {
                    _positions[_index] = _pos[j];
                    _index++;
                }
            }
            return _positions;
        }

        return IMarket(market).getPositions(account);
    }

    /**
     * @dev This function retrieves the funding fee for a specific account's position in a given market.
     * @param account The address of the account whose position the funding fee is being retrieved for.
     * @param market The address of the market in which the position exists.
     * @param isLong A boolean indicating whether the position is a long position.
     * @return The funding fee associated with the specified position.
     */
    function getFundingFee(
        address account,
        address market,
        bool isLong
    ) external view returns (int256) {
        IPositionBook positionBook = IMarket(market).positionBook();
        Position.Props memory _position;
        _position = positionBook.getPosition(account, 0, isLong);

        IFeeRouter _fr = IMarket(market).feeRouter();
        MarketDataTypes.UpdatePositionInputs memory _params;

        _params._isLong = isLong;
        _params.collateralDelta = _position.collateral;
        _params._market = market;

        int256[] memory _fees = _fr.getFees(_params, _position);
        return _fees[2];
    }

    function calZeros(uint y) private pure returns (uint i) {
        uint z = 1;
        while (true) {
            unchecked {
                ++i;
            }
            z *= 10;
            if (z == y) {
                break;
            }
        }
    }
}
