// SPDX-License-Identifier: BUSL-1.1
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
