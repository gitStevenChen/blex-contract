// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/EnumerableValues.sol";

import "../ac/Ac.sol";

contract FeeVault is Ac {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal markets;
    mapping(address => int256) public marketFees; // market -> fee
    mapping(address => int256) public accountFees; // account -> fee
    mapping(uint8 => int256) public kindFees; // fee kind -> fee
    mapping(address => mapping(uint8 => int256)) public marketKindFees; // market -> kind -> fee
    mapping(address => mapping(uint8 => int256)) public accountKindFees; // account -> kind -> fee
    // withdraw fee info
    mapping(address => int256) public toAccountFees; // market, account withdraw fee amount
    mapping(uint8 => int256) public toKindFees;

    // cumulativeFundingRates tracks the funding rates based on utilization
    mapping(address => mapping(bool => int256)) public cumulativeFundingRates;
    // fundingRates tracks the funding rates based on position size
    mapping(address => mapping(bool => int256)) public fundingRates;
    // lastFundingTimes tracks the last time funding was updated for a token
    mapping(address => uint256) public lastFundingTimes;

    event Withdraw(address indexed token, address indexed to, uint256 amount);
    event UpdateCumulativeFundRate(
        address indexed market,
        int256 longRate,
        int256 shortRate
    );
    event UpdateFundRate(
        address indexed market,
        int256 longRate,
        int256 shortRate
    );
    event UpdateLastFundTime(address indexed market, uint256 timestamp);

    constructor() Ac(msg.sender) {}

    function getGlobalFees() external view returns (int256 total) {
        for (uint i = 0; i < markets.values().length; i++) {
            total += marketFees[markets.at(i)];
        }
    }

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(WITHDRAW_ROLE) {
        IERC20(token).safeTransfer(to, amount);
        emit Withdraw(token, to, amount);
    }

    function decreaseFees(
        address market,
        address account,
        int256[] memory fees
    ) external onlyController {
        require(fees.length > 0, "invalid params");

        int256 _toMarketFees;
        int256 _toAccountFees;

        for (uint8 i = 0; i < fees.length; i++) {
            if (fees[i] == 0) {
                continue;
            }

            _toMarketFees += fees[i];
            _toAccountFees += fees[i];
            toKindFees[i] += fees[i];
        }

        toAccountFees[market] += _toMarketFees;
        toAccountFees[account] += _toAccountFees;
    }

    function increaseFees(
        address market,
        address account,
        int256[] memory fees
    ) external onlyController {
        require(fees.length > 0, "invalid params");

        int256 _marketFees;
        int256 _accountFees;

        for (uint8 i = 0; i < fees.length; i++) {
            if (fees[i] == 0) {
                continue;
            }

            _marketFees += fees[i];
            _accountFees += fees[i];
            kindFees[i] += fees[i];
            marketKindFees[market][i] += fees[i];
            accountKindFees[account][i] += fees[i];
        }

        marketFees[market] += _marketFees;
        markets.add(market);
        accountFees[account] += _accountFees;
    }

    function updateGlobalFundingRate(
        address market,
        int256 longRate,
        int256 shortRate,
        int256 nextLongRate,
        int256 nextShortRate,
        uint256 timestamp
    ) external onlyController {
        cumulativeFundingRates[market][true] += nextLongRate;
        fundingRates[market][true] = longRate;

        cumulativeFundingRates[market][false] += nextShortRate;
        fundingRates[market][false] = shortRate;

        lastFundingTimes[market] = timestamp;

        emit UpdateCumulativeFundRate(market, nextLongRate, nextShortRate);
        emit UpdateFundRate(market, longRate, shortRate);
        emit UpdateLastFundTime(market, timestamp);
    }
}
