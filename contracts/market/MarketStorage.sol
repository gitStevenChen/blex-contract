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

import {IMarketStorage} from "./interfaces/IMarket.sol";
import "../order/interface/IOrderBook.sol";
import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import {IPositionStore} from "../position/interfaces/IPositionStore.sol";
import {IFeeVault} from "../fee/interfaces/IFeeVault.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {MarketValid} from "./MarketValid.sol";

contract MarketStorage is IMarketStorage {
    address public override marketValid;
    address public override globalValid;
    address public override indexToken;
    IPositionBook public override positionBook;
    address public override collateralToken;
    IOrderBook public override orderBookLong;
    IOrderBook public override orderBookShort;

    mapping(bool => mapping(bool => IOrderStore)) orderStores;

    function orderStore(
        bool isLong,
        bool isOpen
    ) internal view returns (IOrderStore) {
        return orderStores[isLong][isOpen];
    }

    IFeeRouter public override feeRouter;
    address public override priceFeed;
    address public override positionStoreLong;
    address public override positionStoreShort;

    address public vaultRouter;
    address public positionAddMgr;
    address public positionSubMgr;
    address public orderMgr;
    address public marketRouter;

    string public name;
    address[] public plugins;
    uint256 public constant pluginGasLimit = 666666; // 66w

    uint8 public collateralTokenDigits;

    enum CancelReason {
        Padding, //0
        Liquidation, //1
        PositionClosed, //2
        Executed, //3
        TpAndSlExecuted, //4
        Canceled, //5
        SysCancel, //6invalid order
        PartialLiquidation //7
    }
}
