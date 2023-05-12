// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MockVaultRouter {
    uint256 public fundLimit;
    uint256 public USDBalance;

    mapping(address => uint256) public fundsUsed; // for different market

    function setFundLimit(uint256 _limit) external {
        fundLimit = _limit;
    }

    function setUSDBalance(uint256 _balance) external {
        USDBalance = _balance;
    }

    function borrowFromVault(address _market, uint256 _amount) external {
        fundsUsed[_market] = fundsUsed[_market] + _amount;

        require(fundsUsed[_market] <= fundLimit);
    }

    function repayToVault(address _market, uint256 _amount) external {
        fundsUsed[_market] = fundsUsed[_market] - _amount;
    }

    function getUSDBalance() external view returns (uint256) {
        return USDBalance;
    }
}
