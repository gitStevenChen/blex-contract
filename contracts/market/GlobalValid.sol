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

import "@openzeppelin/contracts/access/Ownable.sol";

import "./GlobalDataTypes.sol";
import "../ac/Ac.sol";

contract GlobalValid is Ac {
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public maxSizeLimit = 10000;
    uint256 public maxNetSizeLimit = 10000;
    uint256 public maxUserNetSizeLimit = 10000;

    mapping(address => uint256) public maxMarketSizeLimit;

    constructor() Ac(msg.sender) {}

    function setMaxSizeLimit(uint256 limit) external onlyRole(GLOBAL_MGR_ROLE) {
        require(
            limit > 0 && limit <= BASIS_POINTS_DIVISOR,
            "globalValid: invalid params"
        );
        maxSizeLimit = limit;
    }

    function setMaxNetSizeLimit(
        uint256 limit
    ) external onlyRole(GLOBAL_MGR_ROLE) {
        require(
            limit > 0 && limit <= BASIS_POINTS_DIVISOR,
            "globalValid: invalid params"
        );
        maxNetSizeLimit = limit;
    }

    function setMaxUserNetSizeLimit(
        uint256 limit
    ) external onlyRole(GLOBAL_MGR_ROLE) {
        require(
            limit > 0 && limit <= BASIS_POINTS_DIVISOR,
            "globalValid: invalid params"
        );
        maxUserNetSizeLimit = limit;
    }

    function setMaxMarketSizeLimit(
        address market,
        uint256 limit
    ) external onlyRole(GLOBAL_MGR_ROLE) {
        require(market != address(0), "globalValid: invalid market");
        require(limit > 0, "globalValid: invalid size limit");

        maxMarketSizeLimit[market] = limit;
    }

    function isIncreasePosition(
        GlobalDataTypes.ValidParams memory params
    ) external view returns (bool) {
        if (params.sizeDelta == 0) {
            return true;
        }

        uint256 _max = _getMaxIncreasePositionSize(params);
        return (_max >= params.sizeDelta);
    }

    function getMaxIncreasePositionSize(
        GlobalDataTypes.ValidParams memory params
    ) external view returns (uint256) {
        return _getMaxIncreasePositionSize(params);
    }

    function _getMaxIncreasePositionSize(
        GlobalDataTypes.ValidParams memory params
    ) private view returns (uint256) {
        uint256 _min = _getMaxUseableGlobalSize(
            params.globalLongSizes,
            params.globalShortSizes,
            params.usdBalance,
            params.isLong
        );
        if (_min == 0) return 0;

        uint256 _tmp = _getMaxUseableNetSize(
            params.globalLongSizes,
            params.globalShortSizes,
            params.usdBalance
        );
        if (_tmp == 0) return 0;

        if (_tmp < _min) _min = _tmp;

        _tmp = _getMaxUseableUserNetSize(
            params.userLongSizes,
            params.userShortSizes,
            params.usdBalance
        );
        if (_tmp == 0) return 0;

        if (_tmp < _min) _min = _tmp;

        _tmp = _getMaxUseableMarketSize(
            params.market,
            params.isLong,
            params.marketLongSizes,
            params.marketShortSizes
        );
        if (_tmp < _min) _min = _tmp;

        return _min;
    }

    function _getMaxUseableGlobalSize(
        uint256 longSize,
        uint256 shortSize,
        uint256 usdBalance,
        bool isLong
    ) private view returns (uint256) {
        uint256 _size = isLong ? longSize : shortSize;
        uint256 _limit = (usdBalance * maxSizeLimit) / BASIS_POINTS_DIVISOR;
        if (_size >= _limit) return 0;
        return (_limit - _size);
    }

    function _getMaxUseableNetSize(
        uint256 longSize,
        uint256 shortSize,
        uint256 usdBalance
    ) private view returns (uint256) {
        uint256 _size = longSize > shortSize
            ? longSize - shortSize
            : shortSize - longSize;
        uint256 _limit = (usdBalance * maxNetSizeLimit) / BASIS_POINTS_DIVISOR;
        if (_size >= _limit) return 0;
        return (_limit - _size);
    }

    function _getMaxUseableUserNetSize(
        uint256 longSize,
        uint256 shortSize,
        uint256 usdBalance
    ) private view returns (uint256) {
        uint256 _size = longSize > shortSize
            ? longSize - shortSize
            : shortSize - longSize;

        uint256 _limit = (usdBalance * maxUserNetSizeLimit) /
            BASIS_POINTS_DIVISOR;
        if (_size >= _limit) return 0;
        return (_limit - _size);
    }

    function _getMaxUseableMarketSize(
        address market,
        bool isLong,
        uint256 longSize,
        uint256 shortSize
    ) private view returns (uint256) {
        uint256 _limit = maxMarketSizeLimit[market];
        uint256 _size = isLong ? longSize : shortSize;

        if (_size >= _limit) return 0;

        return (_limit - _size);
    }
}
