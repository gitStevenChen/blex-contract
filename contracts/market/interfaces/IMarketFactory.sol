// SPDX-License-Identifier: BUSL-1.1
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
