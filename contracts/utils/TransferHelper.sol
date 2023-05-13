// SPDX-License-Identifier: MIT
// Copyright (c) [2023] [BLEX.IO]
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

library Precision {
    uint256 public constant BASIS_POINTS_DIVISOR = 100000000;
    uint256 public constant FEE_RATE_PRECISION_DECIMALS = 8;
    uint256 public constant FEE_RATE_PRECISION =
        10 ** FEE_RATE_PRECISION_DECIMALS;
}

library TransferHelper {
    uint8 public constant usdDecimals = 18;

    using SafeERC20 for IERC20;

    function getUSDDecimals() internal pure returns (uint8) {
        return usdDecimals;
    }

    function formatCollateral(
        uint256 amount,
        uint8 collateralTokenDigits
    ) internal pure returns (uint256) {
        return
            (amount * (10 ** uint256(collateralTokenDigits))) /
            (10 ** usdDecimals);
    }

    function parseVaultAsset(
        uint256 amount,
        uint8 originDigits
    ) internal pure returns (uint256) {
        return (amount * (10 ** uint256(usdDecimals))) / (10 ** originDigits);
    }

    /**
     * @dev This library contains utility functions for transferring assets.
     * @param amount The amount of assets to transfer in integer format with decimal precision.
     * @param collateralTokenDigits The decimal precision of the collateral token.
     * @return The transferred asset amount converted to integer with decimal precision for the USD stablecoin.
     * This function is internal and can only be accessed within the current contract or library.
     */
    function parseVaultAssetSigned(
        int256 amount,
        uint8 collateralTokenDigits
    ) internal pure returns (int256) {
        return
            (amount * int256(10 ** uint256(collateralTokenDigits))) /
            int256(10 ** uint256(usdDecimals));
    }

    //=======================================

    function transferIn(
        address tokenAddress,
        address _from,
        address _to,
        uint256 _tokenAmount
    ) internal {
        if (_tokenAmount == 0) return;
        IERC20 coll = IERC20(tokenAddress);
        coll.safeTransferFrom(
            _from,
            _to,
            formatCollateral(
                _tokenAmount,
                IERC20Decimals(tokenAddress).decimals()
            )
        );
    }

    function transferOut(
        address tokenAddress,
        address _to,
        uint256 _tokenAmount
    ) internal {
        if (_tokenAmount == 0) return;
        IERC20 coll = IERC20(tokenAddress);
        _tokenAmount = formatCollateral(
            _tokenAmount,
            IERC20Decimals(tokenAddress).decimals()
        );
        coll.safeTransfer(_to, _tokenAmount);
    }
}
