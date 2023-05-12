// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {MarketDataTypes} from "../MarketDataTypes.sol";

interface IMarketRouter {
    function updatePositionBook(address newA) external;

    function vaultRouter() external view returns (address);

    function getGlobalPNL() external view returns (int256 pnl);

    function getGlobalSize()
        external
        view
        returns (uint256 sizesLong, uint256 sizesShort);

    function getAccountSize(
        address account
    ) external view returns (uint256 sizesL, uint256 sizesS);

    function addMarket(address) external;

    function removeMarket(address) external;

    function validateIncreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) external view;
}
