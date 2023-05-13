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

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/EnumerableValues.sol";
import "../position/PositionStruct.sol";

contract MockPositionMarket {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;

    // global long/short size
    uint256 public globalLongSizes;
    uint256 public globalShortSizes;

    // each market's long/short size
    mapping(address => uint256) public marketLongSizes;
    mapping(address => uint256) public marketShortSizes;
    // user total long/short size
    mapping(address => uint256) public userLongSizes;
    mapping(address => uint256) public userShortSizes;

    // set of market address
    EnumerableSet.AddressSet private markets;
    // save global position
    mapping(bytes32 => Position.Props) public globalPositions;

    function setGlobalLongSize(uint256 size) external {
        globalLongSizes = size;
    }

    function setGlobalShortSize(uint256 size) external {
        globalShortSizes = size;
    }

    function setMarketLongSize(address market, uint256 size) external {
        require(market != address(0), "invalid market");
        marketLongSizes[market] = size;
    }

    function setMarketShortSize(address market, uint256 size) external {
        require(market != address(0), "invalid market");
        marketShortSizes[market] = size;
    }

    function setUserLongSize(address account, uint256 size) external {
        require(account != address(0), "invalid account");
        userLongSizes[account] = size;
    }

    function setUserShortSize(address account, uint256 size) external {
        require(account != address(0), "invalid account");
        userShortSizes[account] = size;
    }

    function increaseGlobalPosition(
        address account,
        address market,
        uint256 collateralDelta,
        uint256 sizeDelta,
        uint256 averagePrice,
        bool isLong
    ) external {}

    function decreaseGlobalPosition(
        address account,
        address market,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong
    ) external {}
}
