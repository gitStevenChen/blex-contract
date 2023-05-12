// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MockFeeRouter {
    uint256 private constant FEE_RATE_PRECISION = 100000000;

    int256 private fundFee = 100000;
    uint256 private execFee;
    uint256 private liquidateFee;
    uint256 private openFeeRate;
    uint256 private closeFeeRate;
    // cumulativeFundingRates tracks the funding rates based on utilization
    mapping(address => mapping(bool => int256)) public cumulativeFundingRates;

    function setFundFee(int256 _fee) external {
        fundFee = _fee;
    }

    function setExecAndLiquidateFees(
        uint256 _execFee,
        uint256 _liquidateFee
    ) external {
        execFee = _execFee;
        liquidateFee = _liquidateFee;
    }

    function setOpenCloseFeeRate(
        uint256 _openFeeRate,
        uint256 _closeFeeRate
    ) external {
        openFeeRate = _openFeeRate;
        closeFeeRate = _closeFeeRate;
    }

    function setCumulativeFundingRates(
        address market,
        bool isLong,
        int256 rate
    ) external {
        cumulativeFundingRates[market][isLong] = rate;
    }

    function updateCumulativeFundingRate(address market) external {}

    function getExecFee(address _market) public view returns (uint256) {
        return execFee;
    }

    function getLiquidateFee(address _market) external view returns (uint256) {
        return liquidateFee;
    }

    function getFundingFee(
        address _account,
        address _market,
        bool _isLong
    ) public view returns (int256) {
        return fundFee;
    }

    function getOpenFee(
        address _market,
        uint256 _sizeDelta
    ) public view returns (uint256) {
        if (_sizeDelta == 0) {
            return 0;
        }

        uint256 _point = openFeeRate;
        uint256 _size = (_sizeDelta * (FEE_RATE_PRECISION - _point)) /
            FEE_RATE_PRECISION;
        return (_sizeDelta - _size);
    }

    function getCloseFee(
        address _market,
        uint256 _sizeDelta
    ) public view returns (uint256) {
        if (_sizeDelta == 0) {
            return 0;
        }

        uint256 _point = closeFeeRate;
        uint256 _size = (_sizeDelta * (FEE_RATE_PRECISION - _point)) /
            FEE_RATE_PRECISION;

        return (_sizeDelta - _size);
    }

    function getLiquidateFees(
        address _account,
        address _market,
        bool _isLong,
        uint256 _size
    ) external view returns (int256) {
        int256 _fees = getFees(_account, _market, _isLong, _size, false, false);

        _fees += int256(liquidateFee);
        return _fees;
    }

    function getCollateralFees(
        address _account,
        address _market,
        bool _isLong
    ) external view returns (int256) {
        return getFundingFee(_account, _market, _isLong);
    }

    function getFees(
        address _account,
        address _market,
        bool _isLong,
        uint256 _size,
        bool _isExec,
        bool _isOpen
    ) public view returns (int256) {
        int256 _fees;
        uint256 _miscFees;

        if (_isOpen) {
            _miscFees += getOpenFee(_market, _size);
        } else {
            _miscFees += getCloseFee(_market, _size);
            _fees += getFundingFee(_account, _market, _isLong);
        }
        if (_isExec) {
            _fees += int256(execFee);
        }
        return _fees + int256(_miscFees);
    }
}
