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

interface IMarketFactory {
    struct Outs {
        string name;
        address addr;
        bool allowOpen;
        bool allowClose;
    }

    struct CreateInputs {
        string _name; //1
        address _marketAddress; //2
        address[] addrs;
        address _openStoreLong; //11
        address _closeStoreLong; //12
        address _openStoreShort; //13
        address _closeStoreShort; //14
        uint256 _minSlippage;
        uint256 _maxSlippage;
        uint256 _minLeverage;
        uint256 _maxLeverage;
        uint256 _maxTradeAmount;
        uint256 _minPay;
        uint256 _minCollateral;
        bool _allowOpen;
        bool _allowClose;
        uint256 _tokenDigits;
    }

    struct Props {
        string name;
        address addr;
        CreateInputs inputs;
    }

    function getMarkets() external view returns (Outs[] memory _outs);
}
