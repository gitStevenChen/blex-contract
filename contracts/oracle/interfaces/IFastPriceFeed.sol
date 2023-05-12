// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFastPriceFeed {
    function prices(address token) external view returns (uint256);

    function maxCumulativeDeltaDiffs(
        address token
    ) external view returns (uint256);

    function tokens(address index) external view returns (address);

    function tokenPrecisions(uint256 index) external view returns (uint256);

    function setPriceFeed(address _feed) external;

    function setGmxPriceFeed(address feed) external;

    function setMaxTimeDeviation(uint256 _deviation) external;

    function setPriceDuration(uint256 _duration) external;

    function setMaxPriceUpdateDelay(uint256 _delay) external;

    function setSpreadBasisPointsIfInactive(uint256 _point) external;

    function setSpreadBasisPointsIfChainError(uint256 _point) external;

    function setMinBlockInterval(uint256 _interval) external;

    function setIsSpreadEnabled(bool _enabled) external;

    function setIsGmxPriceEnabled(bool enable) external;

    function setLastUpdatedAt(uint256 _lastUpdatedAt) external;

    function setMaxDeviationBasisPoints(
        uint256 _maxDeviationBasisPoints
    ) external;

    function setMaxCumulativeDeltaDiffs(
        address[] memory _tokens,
        uint256[] memory _maxCumulativeDeltaDiffs
    ) external;

    function setPriceDataInterval(uint256 _priceDataInterval) external;

    function setTokens(
        address[] memory _tokens,
        uint256[] memory _tokenPrecisions
    ) external;

    function setPrices(
        address[] memory _tokens,
        uint256[] memory _prices,
        uint256 _timestamp
    ) external;

    function setCompactedPrices(
        uint256[] memory _priceBitArray,
        uint256 _timestamp
    ) external;

    function setPricesWithBits(uint256 _priceBits, uint256 _timestamp) external;

    function getPrice(
        address _token,
        uint256 _refPrice,
        bool _maximise
    ) external view returns (uint256);

    function favorFastPrice(address _token) external view returns (bool);

    function getPriceData(
        address _token
    ) external view returns (uint256, uint256, uint256, uint256);
}
