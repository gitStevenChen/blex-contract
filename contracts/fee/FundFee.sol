// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../ac/Ac.sol";
import {IFeeVault} from "./interfaces/IFeeVault.sol";

contract FundFee is Ownable, Ac {
    address public feeVault;

    uint256 public constant MIN_FUNDING_INTERVAL = 1 hours;
    uint256 public constant FEE_RATE_PRECISION = 100000000;
    uint256 public constant BASIS_INTERVAL_HOU = 24;
    uint256 public constant DEFAILT_RATE_DIVISOR = 100;

    uint256 public minRateLimit = 2083;

    // market's funding rate update interval
    mapping(address => uint256) public fundingIntervals;

    struct SkipTime {
        uint256 start;
        uint256 end;
    }

    SkipTime[] public skipTimes;

    event UpdateMinRateLimit(uint256 indexed oldLimit, uint256 newLimit);
    event UpdateFundInterval(address indexed market, uint256 interval);
    event AddSkipTime(uint256 indexed startTime, uint256 indexed endTime);

    constructor(address vault) Ac(msg.sender) {
        require(vault != address(0), "invalid feeVault");
        feeVault = vault;

        _grantRole(MANAGER_ROLE, msg.sender);
    }

    function setMinRateLimit(uint256 limit) external onlyAdmin {
        require(limit > 0, "invalid limit");

        uint256 _oldLimit = minRateLimit;
        minRateLimit = limit;

        emit UpdateMinRateLimit(_oldLimit, limit);
    }

    function setFundingInterval(
        address[] memory markets,
        uint256[] memory intervals
    ) external onlyAdmin {
        require(markets.length == intervals.length, "invalid params");

        uint256 interval;

        for (uint256 i = 0; i < markets.length; i++) {
            require(markets[i] != address(0));
            require(intervals[i] >= MIN_FUNDING_INTERVAL);

            interval =
                (intervals[i] / MIN_FUNDING_INTERVAL) *
                MIN_FUNDING_INTERVAL;
            fundingIntervals[markets[i]] = intervals[i];

            emit UpdateFundInterval(markets[i], intervals[i]);
        }
    }

    function addSkipTime(uint256 start, uint256 end) external onlyAdmin {
        require(end >= start, "invalid params");

        SkipTime memory _skipTime;
        _skipTime.start = start;
        _skipTime.end = end;
        skipTimes.push(_skipTime);

        emit AddSkipTime(start, end);
    }

    function _getTimeStamp() private view returns (uint256) {
        return block.timestamp;
    }

    function updateCumulativeFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize
    ) external onlyController {
        uint256 _fundingInterval = _getFundingInterval(market);
        uint256 _lastTime = _getLastFundingTimes(market);

        if (_lastTime == 0) {
            _lastTime = (_getTimeStamp() / _fundingInterval) * _fundingInterval;
            _updateGlobalFundingRate(market, 0, 0, 0, 0, _lastTime);
            return;
        }

        if ((_lastTime + _fundingInterval) > _getTimeStamp()) {
            return;
        }

        (int256 _longRate, int256 _shortRate) = _getFundingRate(
            longSize,
            shortSize
        );
        (int256 _longRates, int256 _shortRates) = _getNextFundingRate(
            market,
            _longRate,
            _shortRate
        );

        _lastTime = (_getTimeStamp() / _fundingInterval) * _fundingInterval;

        _updateGlobalFundingRate(
            market,
            _longRate,
            _shortRate,
            _longRates,
            _shortRates,
            _lastTime
        );
    }

    function getFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize,
        bool isLong
    ) external view returns (int256) {
        int256 _rate = IFeeVault(feeVault).fundingRates(market, isLong);
        if (_rate != 0) {
            return _rate;
        }

        (int256 _longRate, int256 _shortRate) = _getFundingRate(
            longSize,
            shortSize
        );
        if (isLong) {
            return _longRate;
        }
        return _shortRate;
    }

    function getFundingFee(
        address market,
        uint256 size,
        int256 entryFundingRate,
        bool isLong
    ) external view returns (int256) {
        if (size == 0) {
            return 0;
        }

        int256 _cumRates = IFeeVault(feeVault).cumulativeFundingRates(
            market,
            isLong
        );
        int256 _divisor = int256(FEE_RATE_PRECISION);

        return _getFundingFee(size, entryFundingRate, _cumRates) / _divisor;
    }

    function getNextFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize
    ) external view returns (int256, int256) {
        (int256 _longRate, int256 _shortRate) = _getFundingRate(
            longSize,
            shortSize
        );

        (int256 _longRates, int256 _shortRates) = _getNextFundingRate(
            market,
            _longRate,
            _shortRate
        );
        return (_longRates, _shortRates);
    }

    function _getFundingRate(
        uint256 longSize,
        uint256 shortSize
    ) private view returns (int256, int256) {
        uint256 _rate = _calFeeRate(longSize, shortSize);
        int256 _sRate = int256(_rate);

        if (_rate == minRateLimit) {
            return (_sRate, _sRate);
        }
        if (longSize >= shortSize) {
            return (_sRate, 0);
        }
        return (0, _sRate);
    }

    function _calFeeRate(
        uint256 _longSize,
        uint256 _shortSize
    ) private view returns (uint256) {
        if (_longSize == 0 && _shortSize == 0) {
            return minRateLimit;
        }

        uint256 _size;
        if (_longSize >= _shortSize) _size = _longSize - _shortSize;
        else _size = _shortSize - _longSize;

        uint256 _rate;
        if (_size != 0) {
            uint256 _divisor = _longSize + _shortSize;

            _rate = (_size * FEE_RATE_PRECISION) / _divisor;
            _rate =
                (_rate ** 2) /
                FEE_RATE_PRECISION /
                DEFAILT_RATE_DIVISOR /
                BASIS_INTERVAL_HOU;
        }

        if (_rate < minRateLimit) {
            return minRateLimit;
        }

        return _rate;
    }

    function _getFundingFee(
        uint256 size,
        int256 entryFundingRate,
        int256 cumRates
    ) private pure returns (int256) {
        int256 _rate = cumRates - entryFundingRate;
        if (_rate == 0) {
            return 0;
        }
        return int256(size) * _rate;
    }

    function _getFundingInterval(
        address market
    ) private view returns (uint256) {
        uint256 _interval = fundingIntervals[market];
        if (_interval != 0) {
            return _interval;
        }

        return MIN_FUNDING_INTERVAL;
    }

    function _getLastFundingTimes(
        address market
    ) private view returns (uint256) {
        return IFeeVault(feeVault).lastFundingTimes(market);
    }

    function _getNextFundingRate(
        address _market,
        int256 _longRate,
        int256 _shortRate
    ) private view returns (int256, int256) {
        uint256 _fundingInterval = _getFundingInterval(_market);
        uint256 _lastTime = _getLastFundingTimes(_market);

        if ((_lastTime + _fundingInterval) > _getTimeStamp()) {
            return (0, 0);
        }

        uint256 _skipTimes = _getSkipTimes();
        int256 _intervals = int256(
            (_getTimeStamp() - _lastTime - _skipTimes) / MIN_FUNDING_INTERVAL
        );

        int256 _longRates = _longRate * _intervals;
        int256 _shortRates = _shortRate * _intervals;

        return (_longRates, _shortRates);
    }

    function _updateGlobalFundingRate(
        address market,
        int256 longRate,
        int256 shortRate,
        int256 nextLongRate,
        int256 nextShortRate,
        uint256 timestamp
    ) private {
        return
            IFeeVault(feeVault).updateGlobalFundingRate(
                market,
                longRate,
                shortRate,
                nextLongRate,
                nextShortRate,
                timestamp
            );
    }

    function _getSkipTimes() private view returns (uint256 totalSkip) {
        if (skipTimes.length == 0) {
            return totalSkip;
        }

        for (uint i = 0; i < skipTimes.length; i++) {
            if (block.timestamp > skipTimes[i].end) {
                totalSkip += (skipTimes[i].end - skipTimes[i].start);
            }
        }
    }
}
