// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../ac/Ac.sol";
import {Calc} from "../utils/Calc.sol";
import "../order/interface/IOrderBook.sol";
import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import {IMarket} from "./interfaces/IMarket.sol";
import {MarketLib} from "./MarketLib.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {IMarketValid, IMarketValidFuncs} from "./interfaces/IMarketValid.sol";

import "../oracle/interfaces/IPrice.sol";
import {MarketConfigStruct} from "./MarketConfigStruct.sol";

import {Position} from "../position/PositionStruct.sol";
import "./MarketDataTypes.sol";
import "./../utils/TransferHelper.sol";

/*
error CollateralValidErr();
error SizeValidErr();
error SlippageValidErr();
error TpValidErr();
error SlValidErr();
error PriceValidErr();
error MarketOfflineErr();
*/
contract MarketValid is Ac, IMarketValidFuncs {
    using Calc for uint256;
    using Calc for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using Order for Order.Props;
    using MarketLib for uint256;
    using MarketConfigStruct for IMarketValid.Props;
    using MarketDataTypes for int256[];

    using MarketDataTypes for MarketDataTypes.UpdateOrderInputs;
    using MarketDataTypes for MarketDataTypes.UpdatePositionInputs;

    IMarketValid.Props public conf;

    constructor(address _f) Ac(_f) {}

    function validPosition(
        MarketDataTypes.UpdatePositionInputs memory _params,
        Position.Props memory _position,
        int256[] memory _fees
    ) external view {
        validSize(_position.size, _params._sizeDelta, _params.isOpen);
        if (_params.isOpen) {
            validCollateralDelta(
                _params.collateralDelta > 0 ? 1 : 2,
                _position.collateral,
                _params.collateralDelta,
                _position.size,
                _params._sizeDelta,
                _fees.totoalFees()
            );
        } else {
            if (_params._sizeDelta != _position.size) {
                validCollateralDelta(
                    _params.collateralDelta > 0 ? 3 : 4,
                    _position.collateral,
                    _params.collateralDelta,
                    _position.size,
                    _params._sizeDelta,
                    _fees.totoalFees()
                );
            }
        }
        if (_params._sizeDelta > 0 && _params.liqState == 0) {
            require(_params._oraclePrice > 0, "invalid oracle price");
            validSlippagePrice(_params);
        }
    }

    function validCollateralDelta(
        uint256 busType, // 1:increase 2. increase coll 3. decrease 4. decrease coll
        uint256 _collateral,
        uint256 _collateralDelta,
        uint256 _size,
        uint256 _sizeDelta,
        int256 _fees
    ) public view override {
        IMarketValid.Props memory _conf = conf;
        if (busType > 2 && _sizeDelta == _size) {
            if (!_conf.getAllowClose()) {
                revert("MarketOfflineErr");
            }
            return;
        }
        uint256 newCollateral = (
            busType < 3
                ? (_collateral + _collateralDelta)
                : (_collateral - _collateralDelta)
        );
        if (busType == 3 && newCollateral == 0) {
            return;
        }

        if (_fees > 0) {
            newCollateral -= uint256(_fees);
        } else {
            newCollateral += uint256(-_fees);
        }

        if (busType == 1) {
            if (!_conf.getAllowOpen()) {
                revert("MarketOfflineErr");
            }
            if (_collateralDelta < _conf.getMinPay()) {
                revert("CollateralValidErr");
            }
        } else if (busType > 2) {
            if (!_conf.getAllowClose()) {
                revert("MarketOfflineErr");
            }
            if (newCollateral < uint256(_conf.getMinCollateral())) {
                revert("CollateralValidErr");
            }
        }

        uint256 newSize = _size;
        if (busType == 1) {
            newSize += _sizeDelta;
        } else if (busType == 3) {
            newSize -= _sizeDelta;
        }

        uint256 lev = newSize / newCollateral;
        if (lev > _conf.getMaxLev() || lev < _conf.getMinLev()) {
            revert("CollateralValidErr");
        }
    }

    function validTPSL(
        uint256 _triggerPrice,
        uint256 _tpPrice,
        uint256 _slPrice,
        bool _isLong
    ) private pure {
        if (_tpPrice > 0) {
            if (
                _tpPrice > _triggerPrice != _isLong || _tpPrice == _triggerPrice
            ) {
                revert("TpValidErr");
            }
        }
        if (_slPrice > 0) {
            if (
                _isLong != _triggerPrice > _slPrice || _slPrice == _triggerPrice
            ) {
                revert("SlValidErr");
            }
        }
    }

    function validIncreaseOrder(
        MarketDataTypes.UpdateOrderInputs memory _vars,
        int256 fees
    ) external view {
        validTPSL(
            _vars._order.price,
            _vars._order.getTakeprofit(),
            _vars._order.getStoploss(),
            _vars._isLong
        );
        validSize(0, _vars._order.price, true);

        validCollateralDelta(1, 0, _vars.pay(), 0, _vars._order.size, fees);
    }

    function validSize(
        uint256 _size,
        uint256 _sizeDelta,
        bool _isIncrease
    ) public pure override {
        
        if (false == _isIncrease) {
            require(_size >= _sizeDelta, "SizeValidErr");
        }
    }

    function validPay(uint256 _pay) external view {
        if (_pay > conf.getMaxTradeAmount()) {
            revert("pay>MaxTradeAmount");
        }
    }

    function getDecreaseOrderValidation(
        uint256 decrOrderCount
    ) external view override returns (bool isValid) {
        return conf.getDecrOrderLmt() >= decrOrderCount + 1;
    }

    function validDecreaseOrder(
        uint256 _collateral,
        uint256 _collateralDelta,
        uint256 _size,
        uint256 _sizeDelta,
        int256 fees,
        uint256 decrOrderCount
    ) external view {
        require(conf.getDecrOrderLmt() >= decrOrderCount + 1, "trigger>10");

        validSize(_size, _sizeDelta, false);
        validCollateralDelta(
            3,
            _collateral,
            _collateralDelta,
            _size,
            _sizeDelta,
            fees
        );
    }

    function getCollateralRange(
        bool _isIncrease,
        uint256 _oldCollertal,
        uint256 _oldSize,
        uint256 _sizeDelta
    )
        public
        view
        override
        returns (uint256 maxCollateralDelta, uint256 minCollateralDelta)
    {
        if (_isIncrease) {
            minCollateralDelta =
                (_sizeDelta + _oldSize) /
                conf.getMinLev() -
                _oldCollertal;
            maxCollateralDelta =
                (_sizeDelta + _oldSize) /
                conf.getMaxLev() -
                _oldCollertal;
        } else {
            uint256 right = (_oldSize - _sizeDelta) / conf.getMinLev();
            minCollateralDelta = _oldCollertal > right
                ? _oldCollertal - right
                : 0;
            maxCollateralDelta =
                _oldCollertal -
                (_oldSize - _sizeDelta) /
                conf.getMaxLev();
        }
    }

    function validMarkPrice(
        bool _isLong,
        uint256 _price,
        bool _isIncrease,
        bool _isExec,
        uint256 _markPrice
    ) public pure override {
        require(_price > 0, "input price zero");
        require(_markPrice > 0, "price zero");

        if (!_isExec) {
            require(
                (_isLong == _isIncrease) == (_price > _markPrice),
                "invalid front-end price"
            );
        }
    }

    function validSlippagePrice(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) public view override {
        if (_inputs._slippage > conf.getMaxSlippage()) {
            _inputs._slippage = conf.getMaxSlippage();
        }

        uint256 _slippagePrice;
        if (_inputs._isLong == _inputs.isOpen) {
            _slippagePrice =
                _inputs._price +
                (_inputs._price * _inputs._slippage) /
                MarketConfigStruct.DENOMINATOR_SLIPPAGE;
        } else {
            _slippagePrice =
                _inputs._price -
                (_inputs._price * _inputs._slippage) /
                MarketConfigStruct.DENOMINATOR_SLIPPAGE;
        }

        validMarkPrice(
            _inputs._isLong,
            _slippagePrice,
            _inputs.isOpen,
            _inputs._isExec,
            _inputs._oraclePrice
        );
    }

    function setConf(
        uint256 _minSlippage,
        uint256 _maxSlippage,
        uint256 _minLeverage,
        uint256 _maxLeverage,
        uint256 _maxTradeAmount,
        uint256 _minPay,
        uint256 _minCollateral,
        bool _allowOpen,
        bool _allowClose,
        uint256
    ) external override onlyRole(MARKET_MGR_ROLE) {
        IMarketValid.Props memory _conf = conf;
        _conf.setMaxLev(_maxLeverage);

        _conf.setMinLev(_minLeverage);
        _conf.setMinSlippage(_minSlippage);
        _conf.setMaxSlippage(_maxSlippage);
        _conf.setMaxTradeAmount(_maxTradeAmount);
        _conf.setMinPay(_minPay);
        _conf.setMinCollateral(_minCollateral);
        _conf.setAllowOpen(_allowOpen);
        _conf.setAllowClose(_allowClose);

        _conf.setDecimals(uint256(TransferHelper.getUSDDecimals()));
        conf = _conf;
    }

    function setConfData(uint256 _data) external onlyRole(MARKET_MGR_ROLE) {
        IMarketValid.Props memory _conf = conf;
        _conf.data = _data;
        conf = _conf;
    }

    function validateLiquidation(
        int256 pnl,
        int256 fees,
        int256 liquidateFee,
        int256 collateral,
        uint256 size,
        bool _raise
    ) public view override returns (uint8) {
        if (pnl < 0 && collateral + pnl < 0) {
            if (_raise) {
                revert("Vault: losses exceed collateral");
            }
            return 1;
        }

        int256 remainingCollateral = collateral;
        if (pnl < 0) {
            remainingCollateral = collateral + pnl;
        }

        if (remainingCollateral < fees) {
            if (_raise) {
                revert("Vault: fees exceed collateral");
            }
            return 1;
        }

        if (remainingCollateral < fees + liquidateFee) {
            if (_raise) {
                revert("Vault: liquidation fees exceed collateral");
            }
            return 1;
        }

        if (
            uint256(remainingCollateral) * conf.getMaxLev() * 10000 <
            size * 10000
        ) {
            if (_raise) {
                revert("Vault: maxLeverage exceeded");
            }
            return 2;
        }

        return 0;
    }

    struct isLiquidateVars {
        uint256 _size;
        uint256 _collateral;
        uint256 _realisedPnl;
        int256 _entryFundingRate;
        bool _hasProfit;
        address _account;
        int256 _totoalFees;
        int256 _liqFee;
    }

    function isLiquidate(
        address _account,
        address _market,
        bool _isLong,
        IPositionBook positionBook,
        IFeeRouter feeRouter,
        uint256 markPrice
    ) public view override returns (uint256 _state) {
        Position.Props memory _position = positionBook.getPosition(
            _account,
            markPrice,
            _isLong
        );
        if (_position.size == 0) {
            return 0;
        }

        MarketDataTypes.UpdatePositionInputs memory _vars;
        _vars.initialize(false);
        _vars._oraclePrice = markPrice;
        _vars._account = _account;
        _vars._isExec = true;
        _vars._isLong = _isLong;
        _vars._sizeDelta = _position.size;
        _vars.collateralDelta = _position.collateral;
        _vars._market = _market;
        _vars.liqState = 1;
        int256[] memory fees = feeRouter.getFees(_vars, _position);

        _state = validateLiquidation(
            _position.realisedPnl,
            fees[1] + fees[2],
            fees[4],
            int256(_position.collateral),
            _position.size,
            false
        );
    }
}

contract MarketValidReader {
    using MarketConfigStruct for IMarketValid.Props;

    address public marketValid;

    constructor(address _addr) {
        marketValid = _addr;
    }

    function getConf() external view returns (uint256) {
        return IMarketValid(marketValid).conf().data;
    }

    function getMinLev() external view returns (uint) {
        IMarketValid.Props memory _confg = IMarketValid(marketValid).conf();
        return _confg.getMinLev();
    }

    function minSlippage() external view returns (uint) {
        IMarketValid.Props memory _confg = IMarketValid(marketValid).conf();
        return _confg.getMinSlippage();
    }

    function maxSlippage() external view returns (uint) {
        IMarketValid.Props memory _confg = IMarketValid(marketValid).conf();
        return _confg.getMaxSlippage();
    }

    function getMaxLev() external view returns (uint) {
        return IMarketValid(marketValid).conf().getMaxLev();
    }
}
