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
pragma experimental ABIEncoderV2;

import "../utils/EnumerableValues.sol";
import "./OrderStruct.sol";
import "../ac/Ac.sol";

contract OrderStore is Ac {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableValues for EnumerableSet.Bytes32Set;
    using Order for Order.Props;

    bool public isLong;

    mapping(bytes32 => Order.Props) public orders;
    EnumerableSet.Bytes32Set internal orderKeys;
    mapping(address => uint256) public ordersIndex;
    mapping(address => uint256) public orderNum;

    mapping(address => EnumerableSet.Bytes32Set) internal ordersByAccount; // position => order

    constructor(address _f) Ac(_f) {}

    function initialize(bool _isLong) external initializeLock {
        isLong = _isLong;
    }

    //===================================

    //===================================
    function add(Order.Props memory order) external onlyController {
        order.updateTime();
        bytes32 key = order.getKey();
        orders[key] = order;
        orderKeys.add(key);
        orderNum[order.account] += 1;
        ordersByAccount[order.account].add(order.getKey());
    }

    //===================================

    //===================================

    function set(Order.Props memory order) external onlyController {
        bytes32 key = order.getKey();
        order.updateTime();
        orders[key] = order;
    }

    //===================================

    //===================================
    function remove(
        bytes32 key
    ) external onlyController returns (Order.Props memory order) {
        if (orderKeys.contains(key)) order = _remove(key);
    }

    function _remove(bytes32 key) internal returns (Order.Props memory _order) {
        _order = orders[key];
        orderNum[_order.account] -= 1;
        delete orders[key];
        orderKeys.remove(key);
        ordersByAccount[_order.account].remove(key);
    }

    //=====================================
    // POSITION KEY
    //=====================================
    function filterOrders(
        bytes32[] memory _ordersKeys
    ) internal view returns (uint256 orderCount) {
        uint256 len = _ordersKeys.length;
        for (uint256 i = 0; i < len; i++) {
            bytes32 _orderKey = _ordersKeys[i];
            if (orderKeys.contains(_orderKey)) {
                orderCount++;
            }
        }
    }

    function delByAccount(
        address account
    ) external onlyController returns (Order.Props[] memory _orders) {
        bytes32[] memory _ordersKeys = ordersByAccount[account].values();
        uint256 orderCount = filterOrders(_ordersKeys);
        uint256 len = _ordersKeys.length;

        _orders = new Order.Props[](orderCount);
        uint256 readIdx;
        for (uint256 i = 0; i < len && readIdx < orderCount; ) {
            bytes32 _orderKey = _ordersKeys[i];
            if (orderKeys.contains(_orderKey)) {
                Order.Props memory _order = _remove(_orderKey);
                _orders[readIdx] = _order;
                unchecked {
                    readIdx++;
                }
            }
            unchecked {
                i++;
            }
        }

        // del key
        delete ordersByAccount[account];
    }

    function getOrderByAccount(
        address account
    ) external view returns (Order.Props[] memory _orders) {
        bytes32[] memory _ordersKeys = ordersByAccount[account].values();
        uint256 orderCount = filterOrders(_ordersKeys);

        _orders = new Order.Props[](orderCount);
        uint256 readIdx;
        uint256 len = _ordersKeys.length;
        for (uint256 i = 0; i < len && readIdx < orderCount; ) {
            bytes32 _orderKey = _ordersKeys[i];
            if (orderKeys.contains(_orderKey)) {
                Order.Props memory _order = orders[_orderKey];
                _orders[readIdx] = _order;
                unchecked {
                    ++readIdx;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    //===================================

    //===================================
    function getByIndex(
        uint256 index
    ) external view returns (Order.Props memory) {
        return orders[orderKeys.at(index)];
    }

    function containsKey(bytes32 key) external view returns (bool) {
        return orderKeys.contains(key);
    }

    function getCount() external view returns (uint256) {
        return orderKeys.length();
    }

    function getKey(uint256 _index) external view returns (bytes32) {
        return orderKeys.at(_index);
    }

    function getKeys(
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory) {
        return orderKeys.valuesAt(start, end);
    }

    function generateID(
        address _acc
    ) external onlyController returns (uint256 retVal) {
        retVal = ordersIndex[_acc];
        if (retVal == 0) {
            retVal = 1;
        }
        unchecked {
            ordersIndex[_acc] = retVal + 1;
        }
    }
}
