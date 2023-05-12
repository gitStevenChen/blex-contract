// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IMarketStorage} from "./interfaces/IMarket.sol";
import "../order/interface/IOrderBook.sol";
import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import {IPositionStore} from "../position/interfaces/IPositionStore.sol";
import {IFeeVault} from "../fee/interfaces/IFeeVault.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {MarketValid} from "./MarketValid.sol";

contract MarketStorage is IMarketStorage {
    address public override marketValid;
    address public override globalValid;
    address public override indexToken;
    IPositionBook public override positionBook;
    address public override collateralToken;
    IOrderBook public override orderBookLong;
    IOrderBook public override orderBookShort;

    mapping(bool => mapping(bool => IOrderStore)) orderStores;

    function orderStore(
        bool isLong,
        bool isOpen
    ) internal view returns (IOrderStore) {
        return orderStores[isLong][isOpen];
    }

    IFeeRouter public override feeRouter;
    address public override priceFeed;
    address public override positionStoreLong;
    address public override positionStoreShort;

    address public vaultRouter;
    address public positionAddMgr;
    address public positionSubMgr;
    address public orderMgr;
    address public marketRouter;

    string public name;
    address[] public plugins;
    uint256 public constant pluginGasLimit = 666666; // 66w

    uint8 public collateralTokenDigits;

    enum CancelReason {
        Padding, //0
        Liquidation, //1
        PositionClosed, //2
        Executed, //3
        TpAndSlExecuted, //4
        Canceled, //5
        SysCancel, //6invalid order
        PartialLiquidation //7
    }
}
