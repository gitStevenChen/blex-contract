// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import "../order/OrderLib.sol";

library MarketDataTypes {
    struct UpdateOrderInputs {
        address _market;
        bool _isLong;
        uint256 _oraclePrice;
        bool isOpen;
        bool isCreate;
        Order.Props _order;
        uint256[] inputs;
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
        _params.inputs = new uint256[](isOpen ? 1 : 0);
        _params.isOpen = isOpen;
    }

    function initialize(
        UpdatePositionInputs memory _params,
        bool isOpen
    ) internal pure {
        _params.inputs = new uint256[](isOpen ? 2 : 1);
        _params.isOpen = isOpen;
    }

    function tp(
        UpdatePositionInputs memory _params
    ) internal pure returns (uint256) {
        return _params.inputs[0];
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
        return _params.inputs[0] > 0;
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
        return _params.inputs[1];
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
        return _params.inputs[0];
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
                if (_params._order.extra0 > 0) return false;
                if (_params._order.extra2 > 0) return false;
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
