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
import {TransferHelper} from "./../utils/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarketStorage.sol";
import "../ac/Ac.sol";

contract OrderMgr is MarketStorage, ReentrancyGuard, Ac {
    using SafeCast for int256;
    using SafeCast for uint256;
    using Order for Order.Props;
    using MarketLib for uint16;
    using MarketDataTypes for int256[];
    using MarketDataTypes for MarketDataTypes.UpdateOrderInputs;
    using MarketDataTypes for MarketDataTypes.UpdatePositionInputs;

    constructor() Ac(address(0)) {}

    /**
     * The `updateOrder` function is used to update an order on the order book. It validates inputs,
     * calculates fees, and triggers events. Depending on the order's state, it either adds a new order or
     * updates an existing one. It also selects the correct order book based on whether the order is long or
     * short. If the order is being created, it calculates the required collateral based on the order size
     * and account position, and validates it against the position collateral and order fees. Finally, it
     * triggers the `afterUpdateOrder` event.
     * */
    function updateOrder(
        MarketDataTypes.UpdateOrderInputs memory _vars
    ) external {
        if (_vars.isOpen && _vars.isCreate) {
            _valid().validPay(_vars.pay());
        }
        if (false == _vars.isOpen)
            _vars._oraclePrice = getPrice(!_vars._isLong);

        IOrderBook ob = _vars._isLong ? orderBookLong : orderBookShort;
        if (_vars.isCreate && _vars.isOpen) {
            _valid().validIncreaseOrder(_vars, feeRouter.getOrderFees(_vars));

            _vars._order.collateral = _vars.pay().toUint128();
        } else if (_vars.isCreate && !_vars.isOpen) {
            Position.Props memory _position = positionBook.getPosition(
                _vars._order.account,
                _vars._oraclePrice,
                _vars._isLong
            );
            _vars._order.collateral = MarketLib
                .getDecreaseDeltaCollateral(
                    _vars._order.extra3 > 0,
                    _position.size,
                    uint256(_vars._order.size),
                    _position.collateral
                )
                .toUint128();

            _valid().validDecreaseOrder(
                _position.collateral,
                uint256(_vars._order.collateral),
                _position.size,
                _vars._order.size,
                feeRouter.getOrderFees(_vars),
                orderStore(_vars._isLong, _vars.isOpen).orderNum(
                    _vars._order.account
                )
            );
        }

        MarketDataTypes.UpdateOrderInputs[]
            memory orderVars = new MarketDataTypes.UpdateOrderInputs[](1);
        orderVars[0] = _vars;
        _vars._order = _vars.isCreate ? ob.add(orderVars)[0] : ob.update(_vars);

        MarketLib.afterUpdateOrder(
            _vars,
            pluginGasLimit,
            plugins,
            collateralToken,
            address(this)
        );
    }

    function getPrice(bool _isMax) private view returns (uint256) {
        IPrice _p = IPrice(priceFeed);
        return _p.getPrice(indexToken, _isMax);
    }

    /**
 * The `cancelOrderList` function cancels multiple orders belonging to a given account. It requires
administrative access control or controller role. It takes in three arrays: one containing booleans
that specify whether each order being cancelled is an increase or decrease order, another containing
the order IDs, and a third containing booleans that specify whether each order is long or short.
The function iterates over each order, removes it from the order book, and calls `_cancelOrder`
to calculate the refundable collateral amount. Finally, it transfers the refunded collateral to the
account.
 */
    function cancelOrderList(
        address _account,
        bool[] memory _isIncreaseList,
        uint256[] memory _orderIDList,
        bool[] memory _isLongList
    ) external {
        require(
            _isIncreaseList.length == _orderIDList.length,
            "OrderMgr:input length"
        );
        require(
            _isLongList.length == _orderIDList.length,
            "OrderMgr:input length"
        );
        uint len = _orderIDList.length;
        uint256 collateralRefund;
        for (uint i; i < len; ) {
            Order.Props memory _or = (
                _isLongList[i] ? orderBookLong : orderBookShort
            ).remove(_account, _orderIDList[i], _isIncreaseList[i])[0];

            collateralRefund += _cancelOrder(
                _or,
                _isLongList[i],
                _isIncreaseList[i],
                false,
                false
            );

            unchecked {
                ++i;
            }
        }
        TransferHelper.transferOut(collateralToken, _account, collateralRefund);
    }

    /**
     * @notice Allows manager to cancel orders from the order book by specifying an array of order keys,
     *  whether the order is long or short, and whether the order is to be increased or decreased.
     * @dev Only callable by the system contract
     * @param _orderKey An array of order keys
     * @param _isLong An array indicating whether each order is a long order
     * @param _isIncrease An array indicating whether each order is to be increased or decreased
     */
    function sysCancelOrder(
        bytes32[] memory _orderKey,
        bool[] memory _isLong,
        bool[] memory _isIncrease
    ) external {
        require(_orderKey.length == _isLong.length);
        require(_isIncrease.length == _isLong.length);
        for (uint i = 0; i < _orderKey.length; i++) {
            require(_orderKey[i] != bytes32(0), "OrderMgr:invalid order key");
            Order.Props[] memory exeOrders = (
                _isLong[i] ? orderBookLong : orderBookShort
            ).remove(_orderKey[i], _isIncrease[i]);
            _cancelOrder(exeOrders[0], _isLong[i], _isIncrease[i], true, true);
        }
    }

    /**
     * @dev Cancels an order, returns the collateral or transfers it to the user based on parameters passed
     * @param _order The order that needs to be canceled
     * @param _isLong A boolean value representing whether the order is for a long position
     * @param _isIncrease A boolean value representing whether the order is increasing a position or not
     * @param _isTransferToUser A boolean value representing whether the collateral needs to be transferred to the user or not
     * @param isExec A boolean value representing whether the order is being executed or not
     * @return collateralRefund The collateral amount that needs to be refunded to the user
     */
    function _cancelOrder(
        Order.Props memory _order,
        bool _isLong,
        bool _isIncrease,
        bool _isTransferToUser,
        bool isExec
    ) internal returns (uint256 collateralRefund) {
        uint256 execFee = isExec ? feeRouter.getExecFee(address(this)) : 0;
        if (_isIncrease) {
            if (execFee > 0) {
                IERC20(collateralToken).approve(address(feeRouter), execFee);

                int256[] memory _fees = new int256[](4);
                _fees[3] = int256(execFee);
                feeRouter.collectFees(_order.account, collateralToken, _fees);
            }
            if (_isTransferToUser) {
                TransferHelper.transferOut(
                    collateralToken,
                    _order.account,
                    _order.collateral - execFee
                );
            } else {
                collateralRefund = _order.collateral;
            }
        } else if (isExec) {
            (uint256 _longSize, uint256 _shortSize) = positionBook
                .getMarketSizes();
            int256 _fundRate = feeRouter.getFundingRate(
                address(this),
                _longSize,
                _shortSize,
                _isLong
            );
            uint256 decreasedCollateral = positionBook
                .decreaseCollateralFromCancelInvalidOrder(
                    _order.account,
                    execFee,
                    _fundRate,
                    _isLong
                );
            if (decreasedCollateral >= execFee) {
                int256[] memory _fees = new int256[](4);
                _fees[3] = int256(execFee);
                IERC20(collateralToken).approve(address(feeRouter), execFee);
                feeRouter.collectFees(_order.account, collateralToken, _fees);
            }
        }

        MarketDataTypes.UpdatePositionInputs memory inputs;
        inputs._market = address(this);
        inputs._isLong = _isLong;
        inputs._oraclePrice = getPrice(true);
        inputs.isOpen = _isIncrease;

        MarketLib.afterDeleteOrder(
            MarketOrderCallBackIntl.DeleteOrderEvent(
                _order,
                inputs,
                uint8(isExec ? CancelReason.SysCancel : CancelReason.Canceled),
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
}
