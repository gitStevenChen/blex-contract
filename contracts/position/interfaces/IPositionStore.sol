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

import "../PositionStruct.sol";

interface IPositionStore {
    function positionBook() external view returns (address);

    function isLong() external view returns (bool);

    function get(address account) external view returns (Position.Props memory);

    function globalSize() external view returns (uint256);

    function getGlobalPosition() external view returns (Position.Props memory);

    function contains(address account) external view returns (bool);

    function getPositionCount() external view returns (uint256);

    function getPositionKeys(
        uint256 start,
        uint256 end
    ) external view returns (address[] memory);

    function setPositionBook(address positionBook) external;

    function set(
        address account,
        Position.Props calldata position,
        Position.Props calldata globalPosition
    ) external;

    function remove(
        address account,
        Position.Props calldata globalPosition
    ) external;
}
