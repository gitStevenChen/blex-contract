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

contract MockFeeStore {
    // key -> feeType -> amount
    mapping(bytes32 => mapping(uint8 => int256)) public accountFees;

    // cumulativeFundingRates tracks the funding rates based on utilization
    mapping(address => mapping(bool => int256)) public cumulativeFundingRates;
    // fundingRates tracks the funding rates based on position size
    mapping(address => mapping(bool => int256)) public fundingRates;
    // lastFundingTimes tracks the last time funding was updated for a token
    mapping(address => uint256) public lastFundingTimes;

    function setCumulativeFundingRates(
        address market,
        bool isLong,
        int256 rate
    ) external {
        require(market != address(0), "invalid market");
        cumulativeFundingRates[market][isLong] = rate;
    }

    function increaseFee(bytes32 key, uint8 kind, int256 fee) external {
        if (fee == 0) {
            return;
        }

        int256 _fee = accountFees[key][kind];
        _fee = _fee + fee;
        accountFees[key][kind] = _fee;
    }

    function updateGlobalFundingRate(
        address market,
        int256 longRate,
        int256 shortRate,
        int256 nextLongRate,
        int256 nextShortRate,
        uint256 timestamp
    ) external {
        cumulativeFundingRates[market][true] =
            cumulativeFundingRates[market][true] +
            nextLongRate;
        fundingRates[market][true] = longRate;

        cumulativeFundingRates[market][false] =
            cumulativeFundingRates[market][false] +
            nextShortRate;
        fundingRates[market][false] = shortRate;

        lastFundingTimes[market] = timestamp;
    }
}
