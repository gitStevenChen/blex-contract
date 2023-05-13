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

interface IMarketReader {
    struct ValidOuts {
        uint256 minSlippage;
        uint256 maxSlippage;
        uint256 slippageDigits;
        uint256 minLev;
        uint256 maxLev;
        uint256 minCollateral;
        uint256 maxTradeAmount;
        bool allowOpen;
        bool allowClose;
    }

    struct MarketOuts {
        uint256 tokenDigits;
        uint256 closeFeeRate;
        uint256 openFeeRate;
        uint256 liquidationFeeUsd;
        uint256 spread;
        address indexToken;
        address collateralToken;
        address orderBookLong;
        address orderBookShort;
        address positionBook;
    }

    struct FeeOuts {
        uint256 closeFeeRate;
        uint256 openFeeRate;
        uint256 execFee;
        uint256 liquidateFee;
        uint256 digits;
    }
    struct PositionOuts {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        int256 entryFundingRate;
        uint256 realisedPnl;
        bool hasProfit;
        uint256 lastTime;
        bool isLong;
        uint256[] orderIDs;
    }
}
