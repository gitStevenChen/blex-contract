// SPDX-License-Identifier: MIT
// Copyright (c) [2023] [BLEX.IO]
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
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
