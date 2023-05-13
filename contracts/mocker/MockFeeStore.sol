// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

contract MockFeeStore {
    // key -> feeType -> amount
    mapping(bytes32 => mapping(uint8 => int256)) public accountFees;

    // cumulativeFundingRates tracks the funding rates based on utilization
    mapping(address => mapping(bool => int256)) public cumulativeFundingRates;
    // fundingRates tracks the funding rates based on position size
    mapping(address => mapping(bool => int256)) public fundingRates;
    // lastFundingTimes tracks the last time funding was updated for a token
    mapping(address => uint256) public lastFundingTimes;

    function setCumulativeFundingRates(
        address market,
        bool isLong,
        int256 rate
    ) external {
        require(market != address(0), "invalid market");
        cumulativeFundingRates[market][isLong] = rate;
    }

    function increaseFee(bytes32 key, uint8 kind, int256 fee) external {
        if (fee == 0) {
            return;
        }

        int256 _fee = accountFees[key][kind];
        _fee = _fee + fee;
        accountFees[key][kind] = _fee;
    }

    function updateGlobalFundingRate(
        address market,
        int256 longRate,
        int256 shortRate,
        int256 nextLongRate,
        int256 nextShortRate,
        uint256 timestamp
    ) external {
        cumulativeFundingRates[market][true] =
            cumulativeFundingRates[market][true] +
            nextLongRate;
        fundingRates[market][true] = longRate;

        cumulativeFundingRates[market][false] =
            cumulativeFundingRates[market][false] +
            nextShortRate;
        fundingRates[market][false] = shortRate;

        lastFundingTimes[market] = timestamp;
    }
}
