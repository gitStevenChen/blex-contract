// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IOrderBook} from "../order/interface/IOrderBook.sol";
import {IPrice} from "../oracle/interfaces/IPrice.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {Calc} from "../utils/Calc.sol";
import {IMarketValid} from "./interfaces/IMarketValid.sol";
import {MarketLib} from "./MarketLib.sol";
import {Order} from "../order/OrderStruct.sol";
import {OrderLib} from "./../order/OrderLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {MarketConfigStruct} from "./MarketConfigStruct.sol";
import {MarketPositionCallBackIntl, MarketOrderCallBackIntl} from "./interfaces/IMarketCallBackIntl.sol";
import {MarketDataTypes} from "./MarketDataTypes.sol";
import {Position} from "../position/PositionStruct.sol";
import {IReferral} from "../referral/interfaces/IReferral.sol";
import {TransferHelper, IERC20Decimals} from "./../utils/TransferHelper.sol";
import "./MarketStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../ac/Ac.sol";
import {IVaultRouter} from "./../vault/interfaces/IVaultRouter.sol";
import "./interfaces/IMarketRouter.sol";

contract PositionAddMgr is MarketStorage, ReentrancyGuard, Ac {
    using SafeCast for int256;
    using SafeCast for uint256;
    using Order for Order.Props;
    using MarketLib for uint16;
    using MarketDataTypes for int256[];
    using MarketDataTypes for MarketDataTypes.UpdateOrderInputs;
    using MarketDataTypes for MarketDataTypes.UpdatePositionInputs;

    constructor() Ac(address(0)) {}

    /**
     * @notice Increases a position and placing take profit and stop loss orders
     * @dev Can only be called internally by the contract, takes a struct _inputs that contains the updated position information
     * @param _inputs The struct containing parameters needed to update the position
     */
    function increasePositionWithOrders(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) public {
        if (false == _inputs.isValid()) {
            if (_inputs._isExec) return;
            else revert("PositionAddMgr:invalid params");
        }
        _valid().validPay(_inputs.collateralDelta);

        if (_inputs._slippage == 0 && 0 == _inputs._fromOrder) {
            _inputs._slippage = 30;
        }

        if (_inputs._sizeDelta > 0)
            _inputs._oraclePrice = getPrice(_inputs._isLong);
        Position.Props memory _position = positionBook.getPosition(
            _inputs._account,
            _inputs._sizeDelta == 0 ? 0 : _inputs._oraclePrice,
            _inputs._isLong
        );

        _increasePosition(_inputs, _position);

        if (
            false ==
            _shouldCreateDecreaseOrder(_inputs._account, _inputs._isLong) ||
            _inputs._sizeDelta == 0
        ) {
            return;
        }

        bool placeTp = _inputs.tp() != 0 &&
            (_inputs.tp() > _inputs._price == _inputs._isLong ||
                _inputs.tp() == _inputs._price);

        bool placeSl = _inputs.sl() != 0 &&
            (_inputs._isLong == _inputs._price > _inputs.sl() ||
                _inputs._price == _inputs.sl());

        MarketDataTypes.UpdateOrderInputs[] memory _vars;
        uint256 ordersCount = placeTp && placeSl
            ? 2
            : (placeTp || placeSl ? 1 : 0);
        if (ordersCount > 0) {
            _vars = new MarketDataTypes.UpdateOrderInputs[](ordersCount);
            _vars[0] = _buildDecreaseVars(
                _inputs,
                0,
                placeTp ? _inputs.tp() : _inputs.sl(),
                placeTp
            );

            if (ordersCount == 2) {
                _vars[1] = _buildDecreaseVars(_inputs, 0, _inputs.sl(), false);
            }
        } else return;

        Order.Props[] memory _os = (
            _inputs._isLong ? orderBookLong : orderBookShort
        ).add(_vars);
        uint256[] memory inputs = new uint256[](0);
        for (uint i; i < _os.length; ) {
            Order.Props memory _order = _os[i];

            MarketLib.afterUpdateOrder(
                MarketDataTypes.UpdateOrderInputs({
                    _market: address(this),
                    _isLong: _inputs._isLong,
                    _oraclePrice: _inputs._oraclePrice,
                    isOpen: false,
                    isCreate: true,
                    _order: _order,
                    inputs: inputs
                }),
                pluginGasLimit,
                plugins,
                collateralToken,
                address(this)
            );

            unchecked {
                ++i;
            }
        }
    }

    function commitIncreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _params,
        int256 collD,
        int256 fr
    ) private {
        if (_params._sizeDelta == 0 && collD < 0) {
            positionBook.decreasePosition(
                _params._account,
                uint256(-collD),
                _params._sizeDelta,
                fr,
                _params._isLong
            );
        } else {
            IVaultRouter(vaultRouter).borrowFromVault(
                TransferHelper.formatCollateral(
                    _params._sizeDelta,
                    IERC20Decimals(collateralToken).decimals()
                )
            );
            positionBook.increasePosition(
                _params._account,
                collD.toUint256(),
                _params._sizeDelta,
                _params._oraclePrice,
                fr,
                _params._isLong
            );
        }
    }

    function _increasePosition(
        MarketDataTypes.UpdatePositionInputs memory _params,
        Position.Props memory _position
    ) private returns (int256 collD) {
        MarketLib._updateCumulativeFundingRate(positionBook, feeRouter);
        _params._market = address(this);
        int256[] memory _fees = feeRouter.getFees(_params, _position);
        int256 _totalfee = _fees.totoalFees();

        if (_params._sizeDelta > 0) {
            _valid().validPosition(_params, _position, _fees);
        } else {
            _valid().validCollateralDelta(
                2,
                _position.collateral,
                _params.collateralDelta,
                _position.size,
                0,
                _totalfee
            );
        }

        int256 _fundingRate = feeRouter.cumulativeFundingRates(
            address(this),
            _params._isLong
        );
        collD = _params.collateralDelta.toInt256() - _totalfee;
        commitIncreasePosition(_params, collD, _fundingRate);
        validLiq(_params._account, _params._isLong);

        _transationsFees(_totalfee);

        feeRouter.collectFees(_params._account, collateralToken, _fees);

        MarketLib.afterUpdatePosition(
            MarketPositionCallBackIntl.UpdatePositionEvent(
                _params,
                _position,
                _fees,
                collateralToken,
                indexToken,
                collD
            ),
            pluginGasLimit,
            plugins,
            collateralToken,
            address(this)
        );
    }

    function getPrice(bool _isMax) private view returns (uint256 p) {
        IPrice _p = IPrice(priceFeed);
        p = _p.getPrice(indexToken, _isMax);
        require(p > 0, "invalid price");
    }

    function _transationsFees(int256 fees) private {
        if (fees < 0) {
            IFeeRouter(feeRouter).withdraw(
                collateralToken,
                address(this),
                uint(fees * -1)
            );
        } else if (fees > 0) {
            uint256 amount = TransferHelper.formatCollateral(
                uint(fees),
                IERC20Decimals(collateralToken).decimals()
            );
            IERC20(collateralToken).approve(address(feeRouter), amount);
        }
    }

    function execOrderKey(
        Order.Props memory exeOrder,
        MarketDataTypes.UpdatePositionInputs memory _params
    ) external {
        Order.validOrderAccountAndID(exeOrder);
        require(_params.isOpen, "PositionAddMgr:invalid isopen");
        _execIncreaseOrderKey(exeOrder, _params);
    }

    function _execIncreaseOrderKey(
        Order.Props memory order,
        MarketDataTypes.UpdatePositionInputs memory _params
    ) private {
        require(order.account != address(0), "PositionAddMgr:invalid account");
        IMarketRouter(marketRouter).validateIncreasePosition(_params);
        increasePositionWithOrders(_params);
        require(
            order.isMarkPriceValid(_params._oraclePrice),
            "PositionAddMgr::triggerabove"
        );
        (_params._isLong ? orderBookLong : orderBookShort).remove(
            order.getKey(),
            true
        );

        MarketLib.afterDeleteOrder(
            MarketOrderCallBackIntl.DeleteOrderEvent(
                order,
                _params,
                uint8(CancelReason.Executed),
                int256(0)
            ),
            pluginGasLimit,
            plugins,
            collateralToken,
            address(this)
        );
    }

    function _valid() internal view returns (IMarketValid) {
        return IMarketValid(marketValid);
    }

    function validLiq(address acc, bool _isLong) private view {
        require(
            _valid().isLiquidate(
                acc,
                address(this),
                _isLong,
                positionBook,
                feeRouter,
                getPrice(!_isLong)
            ) == 0,
            "PositionAddMgr:position under liq"
        );
    }

    function _shouldCreateDecreaseOrder(
        address account,
        bool isLong
    ) private view returns (bool) {
        return
            _valid().getDecreaseOrderValidation(
                orderStore(isLong, false).orderNum(account)
            );
    }

    function _buildDecreaseVars(
        MarketDataTypes.UpdatePositionInputs memory _inputs,
        uint256 /* collateralIncreased */,
        uint256 triggerPrice,
        bool isTP
    )
        private
        view
        returns (MarketDataTypes.UpdateOrderInputs memory _createVars)
    {
        _createVars.initialize(false);
        _createVars._market = address(this);
        _createVars._isLong = _inputs._isLong;
        _createVars._oraclePrice = getPrice(!_inputs._isLong);
        _createVars.isCreate = true;

        _createVars._order.setFromOrder(_inputs._fromOrder);
        _createVars._order.account = _inputs._account;
        _createVars._order.setSize(_inputs._sizeDelta);
        _createVars._order.collateral = 0;
        _createVars._order.setTriggerAbove(isTP == _inputs._isLong);
        _createVars._order.price = uint128(triggerPrice);
        _createVars._order.refCode = _inputs._refCode;
    }
}
