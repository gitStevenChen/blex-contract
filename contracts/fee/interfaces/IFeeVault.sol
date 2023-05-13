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

interface IFeeVault {
    function marketFees(address market) external view returns (int256);

    function accountFees(address account) external view returns (int256);

    function kindFees(uint8 types) external view returns (int256);

    function marketKindFees(
        address market,
        uint8 types
    ) external view returns (int256);

    function accountKindFees(
        address account,
        uint8 types
    ) external view returns (int256);

    function toAccountFees(address account) external view returns (int256);

    function toKindFees(uint8 types) external view returns (int256);

    function cumulativeFundingRates(
        address market,
        bool isLong
    ) external view returns (int256);

    function fundingRates(
        address market,
        bool isLong
    ) external view returns (int256);

    function lastFundingTimes(address market) external view returns (uint256);

    function decreaseFees(
        address market,
        address account,
        int256[] memory fees
    ) external;

    function increaseFees(
        address market,
        address account,
        int256[] memory fees
    ) external;

    function updateGlobalFundingRate(
        address market,
        int256 longRate,
        int256 shortRate,
        int256 nextLongRate,
        int256 nextShortRate,
        uint256 timestamp
    ) external;

    function withdraw(address token, address to, uint256 amount) external;

    function getGlobalFees() external view returns (int256 total);
}
