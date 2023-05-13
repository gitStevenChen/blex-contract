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

interface IFundFee {
    function MIN_FUNDING_INTERVAL() external view returns (uint256);

    function FEE_RATE_PRECISION() external view returns (uint256);

    function BASIS_INTERVAL_HOU() external view returns (uint256);

    function DEFAILT_RATE_DIVISOR() external view returns (uint256);

    function minRateLimit() external view returns (uint256);

    function feeStore() external view returns (address);

    function fundingIntervals(address) external view returns (uint256);

    function initialize(address store) external;

    function setMinRateLimit(uint256 limit) external;

    function setFundingInterval(
        address[] memory markets,
        uint256[] memory intervals
    ) external;

    function addSkipTime(uint256 start, uint256 end) external;

    function updateCumulativeFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize
    ) external;

    function getFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize,
        bool isLong
    ) external view returns (int256);

    function getFundingFee(
        address market,
        uint256 size,
        int256 entryFundingRate,
        bool isLong
    ) external view returns (int256);

    function getNextFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize
    ) external view returns (int256, int256);
}
