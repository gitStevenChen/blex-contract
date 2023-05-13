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

library Position {
    struct Props {
        address market;
        bool isLong;
        uint32 lastTime;
        uint216 extra3;
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        int256 entryFundingRate;
        int256 realisedPnl;
        uint256 extra0;
        uint256 extra1;
        uint256 extra2;
    }

    function calAveragePrice(
        Props memory position,
        uint256 sizeDelta,
        uint256 markPrice,
        uint256 pnl,
        bool hasProfit
    ) internal pure returns (uint256) {
        uint256 _size = position.size + sizeDelta;
        uint256 _netSize;

        if (position.isLong) {
            _netSize = hasProfit ? _size + pnl : _size - pnl;
        } else {
            _netSize = hasProfit ? _size - pnl : _size + pnl;
        }
        return (markPrice * _size) / _netSize;
    }

    function getLeverage(
        Props memory position
    ) internal pure returns (uint256) {
        return position.size / position.collateral;
    }

    function getPNL(
        Props memory position,
        uint256 price
    ) internal pure returns (bool, uint256) {
        uint256 _priceDelta = position.averagePrice > price
            ? position.averagePrice - price
            : price - position.averagePrice;
        uint256 _pnl = (position.size * _priceDelta) / position.averagePrice;

        bool _hasProfit;

        if (position.isLong) {
            _hasProfit = price > position.averagePrice;
        } else {
            _hasProfit = position.averagePrice > price;
        }

        return (_hasProfit, _pnl);
    }

    function isExist(Props memory position) internal pure returns (bool) {
        return (position.size > 0);
    }

    function isValid(Props memory position) internal pure returns (bool) {
        if (position.size == 0) {
            return false;
        }
        if (position.size < position.collateral) {
            return false;
        }

        return true;
    }
}
