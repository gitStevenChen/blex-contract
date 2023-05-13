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
import {IPositionBook} from "../../position/interfaces/IPositionBook.sol";
import {IFeeRouter} from "../../fee/interfaces/IFeeRouter.sol";
import {IOrderBook} from "../../order/interface/IOrderBook.sol";
import "../../order/OrderStruct.sol";
import {MarketDataTypes} from "../MarketDataTypes.sol";
import "./../../position/PositionStruct.sol";

interface IMarketStorage {
    function marketValid() external view returns (address);

    function globalValid() external view returns (address);

    function indexToken() external view returns (address);

    function positionBook() external view returns (IPositionBook); // slot 2

    function collateralToken() external view returns (address);

    function orderBookLong() external view returns (IOrderBook); // slot 2

    function orderBookShort() external view returns (IOrderBook); // slot 2

    function feeRouter() external view returns (IFeeRouter); // slot 2

    function priceFeed() external view returns (address); // slot 2

    function positionStoreLong() external view returns (address); // slot 2

    function positionStoreShort() external view returns (address); // slot 2
}

interface IMarket is IMarketStorage {
    //=============================
    //user actions
    //=============================
    function increasePositionWithOrders(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) external;

    function decreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _vars
    ) external;

    function updateOrder(
        MarketDataTypes.UpdateOrderInputs memory _vars
    ) external;

    function cancelOrderList(
        address _account,
        bool[] memory _isIncreaseList,
        uint256[] memory _orderIDList,
        bool[] memory _isLongList
    ) external;

    //=============================
    //sys actions
    //=============================
    function initialize(address[] calldata addrs, string memory _name) external;

    function execOrderKey(
        Order.Props memory exeOrder,
        MarketDataTypes.UpdatePositionInputs memory _params
    ) external;

    function liquidatePositions(
        address[] memory accounts,
        bool _isLong
    ) external;

    //=============================
    //read-only
    //=============================
    function getPNL() external view returns (int256);

    function USDDecimals() external pure returns (uint8);

    function priceFeed() external view returns (address);

    function getPositions(
        address account
    ) external view returns (Position.Props[] memory _poss);
}

library MarketAddressIndex {
    uint public constant ADDR_PB = 0;
    uint public constant ADDR_OBL = 1;
    uint public constant ADDR_OBS = 2;

    uint public constant ADDR_MV = 3;
    uint public constant ADDR_PF = 4;

    uint public constant ADDR_PM = 5;
    uint public constant ADDR_MI = 6;

    uint public constant ADDR_IT = 7;
    uint public constant ADDR_FR = 8;
    uint public constant ADDR_MR = 9;

    uint public constant ADDR_VR = 10;
    uint public constant ADDR_CT = 11;
}
