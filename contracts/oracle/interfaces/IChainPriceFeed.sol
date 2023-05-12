// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChainPriceFeed {
    function sampleSpace() external view returns (uint256);

    function priceFeeds(address token) external view returns (address);

    function priceDecimals(address) external view returns (uint256);

    function setSampleSpace(uint256 times) external;

    function setPriceFeed(
        address token,
        address feed,
        uint256 decimal
    ) external;

    function getLatestPrice(address token) external view returns (uint256);

    function getPrice(
        address token,
        bool maximise
    ) external view returns (uint256);
}
