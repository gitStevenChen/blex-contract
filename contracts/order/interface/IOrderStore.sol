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
import "../OrderStruct.sol";

interface IOrderStore {
    function initialize(bool _isLong) external;

    function add(Order.Props memory order) external;

    function set(Order.Props memory order) external;

    function remove(bytes32 key) external returns (Order.Props memory order);

    function delByAccount(
        address account
    ) external returns (Order.Props[] memory _orders);

    function generateID(address _acc) external returns (uint256);

    function setOrderBook(address _ob) external;

    //============================
    function orders(bytes32 key) external view returns (Order.Props memory);

    function getOrderByAccount(
        address account
    ) external view returns (Order.Props[] memory _orders);

    function getKey(uint256 _index) external view returns (bytes32);

    function getKeys(
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory);

    function containsKey(bytes32 key) external view returns (bool);

    function isLong() external view returns (bool);

    // function orderTotalSize(address) external view returns (uint256) ;
    function getCount() external view returns (uint256);

    function orderNum(address _a) external view returns (uint256); // 用户的order数量
}
