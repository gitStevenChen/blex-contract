// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import "../order/OrderLib.sol";
import {Order} from "../order/OrderStruct.sol";

library MarketDataTypes {
    using Order for Order.Props;

    struct UpdateOrderInputs {
        address _market;
        bool _isLong;
        uint256 _oraclePrice;
        bool isOpen;
        bool isCreate;
        Order.Props _order;
        uint256[] inputs; // uint256 pay; bool isFromMarket; uint256 _slippage;
    }

    function isFromMarket(
        UpdateOrderInputs memory _params
    ) internal pure returns (bool) {
        return _params.inputs.length >= 2 && _params.inputs[1] > 0;
    }

    function setIsFromMarket(
        UpdateOrderInputs memory _params,
        bool _p
    ) internal pure {
        _params.inputs[1] = _p ? 1 : 0;
    }

    function slippage(
        UpdateOrderInputs memory _params
    ) internal pure returns (uint256) {
        return _params.inputs.length >= 3 ? _params.inputs[2] : 0;
    }

    function setSlippage(
        UpdateOrderInputs memory _params,
        uint256 _p
    ) internal pure {
        _params.inputs[2] = _p;
    }

    struct UpdatePositionInputs {
        address _market;
        bool _isLong;
        uint256 _oraclePrice;
        bool isOpen;
        address _account;
        uint256 _sizeDelta;
        uint256 _price;
        uint256 _slippage;
        bool _isExec;
        uint8 liqState;
        uint64 _fromOrder;
        bytes32 _refCode;
        uint256 collateralDelta;
        uint8 execNum;
        uint256[] inputs;
    }

    function initialize(
        UpdateOrderInputs memory _params,
        bool isOpen
    ) internal pure {
        _params.inputs = new uint256[](3);
        _params.isOpen = isOpen;
    }

    function initialize(
        UpdatePositionInputs memory _params,
        bool isOpen
    ) internal pure {
        _params.inputs = new uint256[](2);
        _params.isOpen = isOpen;
    }

    function fromOrder(
        UpdatePositionInputs memory _vars,
        Order.Props memory _order,
        address market,
        bool isLong,
        bool isIncrease,
        bool isExec
    ) internal pure {
        _vars._market = market;
        _vars._isLong = isLong;
        _vars._sizeDelta = _order.size;
        _vars._price = _order.price;
        _vars._refCode = _order.refCode;
        _vars._isExec = isExec;
        _vars._fromOrder = _order.orderID;
        _vars._account = _order.account;
        _vars.collateralDelta = _order.collateral;
        if (isIncrease) {
            setTp(_vars, _order.getTakeprofit());
            setSl(_vars, _order.getStoploss());
        } else {
            setIsKeepLev(_vars, _order.getIsKeepLev());
        }
    }

    function tp(
        UpdatePositionInputs memory _params
    ) internal pure returns (uint256) {
        return _params.inputs.length >= 1 ? _params.inputs[0] : 0;
    }

    function setTp(
        UpdatePositionInputs memory _params,
        uint256 _tp
    ) internal pure {
        _params.inputs[0] = _tp;
    }

    function isKeepLev(
        UpdatePositionInputs memory _params
    ) internal pure returns (bool) {
        return _params.inputs.length >= 1 && _params.inputs[0] > 0;
    }

    function setIsKeepLev(
        UpdatePositionInputs memory _params,
        bool _is
    ) internal pure returns (uint256) {
        return _params.inputs[0] = _is ? 1 : 0;
    }

    function sl(
        UpdatePositionInputs memory _params
    ) internal pure returns (uint256) {
        return _params.inputs.length >= 2 ? _params.inputs[1] : 0;
    }

    function setSl(
        UpdatePositionInputs memory _params,
        uint256 _sl
    ) internal pure {
        _params.inputs[1] = _sl;
    }

    function pay(
        UpdateOrderInputs memory _params
    ) internal pure returns (uint256) {
        return _params.inputs.length >= 1 ? _params.inputs[0] : 0;
    }

    function setPay(
        UpdateOrderInputs memory _params,
        uint256 _p
    ) internal pure {
        _params.inputs[0] = _p;
    }

    function isValid(
        UpdatePositionInputs memory /* _params */
    ) internal pure returns (bool) {
        return true;
    }

    function isValid(
        UpdateOrderInputs memory _params
    ) internal pure returns (bool) {
        if (_params._oraclePrice > 0) return false;

        if (false == _params.isOpen) {
            if (_params.isCreate) {
                if (_params._order.getFromOrder() > 0) return false;
                if (_params._order.getPairKey() > 0) return false;
            }
        }
        return true;
    }

    function totoalFees(
        int256[] memory fees
    ) internal pure returns (int256 total) {
        for (uint i = 0; i < fees.length; i++) {
            total += fees[i];
        }
    }
}
