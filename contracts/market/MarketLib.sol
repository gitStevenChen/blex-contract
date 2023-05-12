// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {MarketConfigStruct} from "./MarketConfigStruct.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {IVaultRouter} from "../vault/interfaces/IVaultRouter.sol";
import {IOrderBook} from "../order/interface/IOrderBook.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import {Order} from "../order/OrderStruct.sol";
import {MarketPositionCallBackIntl, MarketOrderCallBackIntl} from "./interfaces/IMarketCallBackIntl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/TransferHelper.sol";
import "./MarketDataTypes.sol";

library MarketLib {
    function feeWithdraw(
        address collAddr,
        address _account,
        int256 fee,
        uint8 collateralTokenDigits,
        address fr
    ) internal {
        require(_account != address(0), "invalid user account");
        if (fee < 0) {
            IFeeRouter(fr).withdraw(
                collAddr,
                _account,
                TransferHelper.formatCollateral(
                    uint256(-fee),
                    collateralTokenDigits
                )
            );
        }
    }

    function vaultWithdraw(
        address /* collAddr */,
        address _account,
        int256 pnl,
        uint8 collateralTokenDigits,
        address vr
    ) internal {
        require(_account != address(0));
        if (pnl > 0) {
            IVaultRouter(vr).transferFromVault(
                _account,
                TransferHelper.formatCollateral(
                    uint256(pnl),
                    collateralTokenDigits
                )
            );
        }
    }

    function getDecreaseDeltaCollateral(
        bool isKeepLev,
        uint256 size,
        uint256 dSize,
        uint256 collateral
    ) internal pure returns (uint256 deltaCollateral) {
        if (isKeepLev) {
            deltaCollateral = (collateral * dSize) / size;
        } else {
            deltaCollateral = 0;
        }
    }

    function afterUpdatePosition(
        MarketPositionCallBackIntl.UpdatePositionEvent memory _item,
        uint256 /* gasLimit */,
        address[] memory plugins,
        address erc20Token,
        address market
    ) internal {
        uint256 balanceBefore = IERC20(erc20Token).balanceOf(market);
        for (uint256 i = 0; i < plugins.length; i++) {
            MarketPositionCallBackIntl(plugins[i]).updatePositionCallback(
                _item
            );
        }
        uint256 balanceAfter = IERC20(erc20Token).balanceOf(market);
        require(balanceAfter == balanceBefore, "ERC20 token balance changed");
    }

    function afterUpdateOrder(
        MarketDataTypes.UpdateOrderInputs memory _item,
        uint256 /* gasLimit */,
        address[] memory plugins,
        address collateralToken,
        address market
    ) internal {
        uint256 balanceBefore = IERC20(collateralToken).balanceOf(market);
        for (uint256 i = 0; i < plugins.length; i++) {
            MarketOrderCallBackIntl(plugins[i]).updateOrderCallback(_item);
        }
        uint256 balanceAfter = IERC20(collateralToken).balanceOf(market);
        require(balanceAfter == balanceBefore, "ERC20 token balance changed");
    }

    function afterDeleteOrder(
        MarketOrderCallBackIntl.DeleteOrderEvent memory e,
        uint256 /* gasLimit */,
        address[] memory plugins,
        address erc20Token,
        address market
    ) internal {
        uint256 balanceBefore = IERC20(erc20Token).balanceOf(market);
        for (uint256 i = 0; i < plugins.length; i++) {
            MarketOrderCallBackIntl(plugins[i]).deleteOrderCallback(e);
        }
        uint256 balanceAfter = IERC20(erc20Token).balanceOf(market);
        require(balanceAfter == balanceBefore, "ERC20 token balance changed");
    }

    function _updateCumulativeFundingRate(
        IPositionBook positionBook,
        IFeeRouter feeRouter
    ) internal {
        (uint256 _longSize, uint256 _shortSize) = positionBook.getMarketSizes();

        feeRouter.updateCumulativeFundingRate(
            address(this),
            _longSize,
            _shortSize
        );
    }
}
