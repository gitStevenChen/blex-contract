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

import {MarketDataTypes} from "../../market/MarketDataTypes.sol";
import {Position} from "../../position/PositionStruct.sol";

interface IFeeRouter {
    enum FeeType {
        OpenFee, // 0
        CloseFee, // 1
        FundFee, // 2
        ExecFee, // 3
        LiqFee, // 4
        BuyLpFee, // 5
        SellLpFee, // 6
        ExtraFee0,
        ExtraFee1,
        ExtraFee2,
        ExtraFee3,
        ExtraFee4,
        Counter
    }

    function feeVault() external view returns (address);

    function fundFee() external view returns (address);

    function FEE_RATE_PRECISION() external view returns (uint256);

    function feeAndRates(
        address market,
        uint8 kind
    ) external view returns (uint256);

    function initialize(address vault, address fundingFee) external;

    function setFeeAndRates(address market, uint256[] memory rates) external;

    function withdraw(address token, address to, uint256 amount) external;

    function getExecFee(address market) external view returns (uint256);

    function getAccountFees(address account) external view returns (uint256);

    function getFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize,
        bool isLong
    ) external view returns (int256);

    function cumulativeFundingRates(
        address market,
        bool isLong
    ) external view returns (int256);

    function updateCumulativeFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize
    ) external;

    function getOrderFees(
        MarketDataTypes.UpdateOrderInputs memory params
    ) external view returns (int256 fees);

    function getFees(
        MarketDataTypes.UpdatePositionInputs memory params,
        Position.Props memory position
    ) external view returns (int256[] memory);

    function collectFees(
        address account,
        address token,
        int256[] memory fees
    ) external;

    function getGlobalFees() external view returns (int256 total);
}
