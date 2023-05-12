// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IFeeVault {
    function marketFees(address market) external view returns (int256);

    function accountFees(address account) external view returns (int256);

    function kindFees(uint8 types) external view returns (int256);

    function marketKindFees(
        address market,
        uint8 types
    ) external view returns (int256);

    function accountKindFees(
        address account,
        uint8 types
    ) external view returns (int256);

    function toAccountFees(address account) external view returns (int256);

    function toKindFees(uint8 types) external view returns (int256);

    function cumulativeFundingRates(
        address market,
        bool isLong
    ) external view returns (int256);

    function fundingRates(
        address market,
        bool isLong
    ) external view returns (int256);

    function lastFundingTimes(address market) external view returns (uint256);

    function decreaseFees(
        address market,
        address account,
        int256[] memory fees
    ) external;

    function increaseFees(
        address market,
        address account,
        int256[] memory fees
    ) external;

    function updateGlobalFundingRate(
        address market,
        int256 longRate,
        int256 shortRate,
        int256 nextLongRate,
        int256 nextShortRate,
        uint256 timestamp
    ) external;

    function withdraw(address token, address to, uint256 amount) external;

    function getGlobalFees() external view returns (int256 total);
}
