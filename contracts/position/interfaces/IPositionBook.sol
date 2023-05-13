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

import "../PositionStruct.sol";

interface IPositionBook {
    function market() external view returns (address);

    function longStore() external view returns (address);

    function shortStore() external view returns (address);

    function initialize(address market) external;

    function getMarketSizes() external view returns (uint256, uint256);

    function getAccountSize(
        address account
    ) external view returns (uint256, uint256);

    function getPosition(
        address account,
        uint256 markPrice,
        bool isLong
    ) external view returns (Position.Props memory);

    function getPositions(
        address account
    ) external view returns (Position.Props[] memory);

    function getPositionKeys(
        uint256 start,
        uint256 end,
        bool isLong
    ) external view returns (address[] memory);

    function getPositionCount(bool isLong) external view returns (uint256);

    function getPNL(
        address account,
        uint256 sizeDelta,
        uint256 markPrice,
        bool isLong
    ) external view returns (int256);

    function getMarketPNL(uint256 markPrice) external view returns (int256);

    function increasePosition(
        address account,
        uint256 collateralDelta,
        uint256 sizeDelta,
        uint256 markPrice,
        int256 fundingRate,
        bool isLong
    ) external returns (Position.Props memory result);

    function decreasePosition(
        address account,
        uint256 collateralDelta,
        uint256 sizeDelta,
        int256 fundingRate,
        bool isLong
    ) external returns (Position.Props memory result);

    function decreaseCollateralFromCancelInvalidOrder(
        address account,
        uint256 collateralDelta,
        int256 fundingRate,
        bool isLong
    ) external returns (uint256);

    function liquidatePosition(
        address account,
        uint256 markPrice,
        bool isLong
    ) external returns (Position.Props memory result);
}
