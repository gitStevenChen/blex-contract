// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IMarketStorage} from "../market/interfaces/IMarket.sol";
import "../order/interface/IOrderBook.sol";
import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import {IPositionStore} from "../position/interfaces/IPositionStore.sol";
import {IFeeVault} from "../fee/interfaces/IFeeVault.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {MarketValid} from "../market/MarketValid.sol";

contract MarketStorage is IMarketStorage {
    //=========================================
    // 合约之间使用的变量
    //=========================================
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
    address public override priceFeed; // 内部使用
    address public override positionStoreLong;
    address public override positionStoreShort;

    //=========================================
    //          本合约内部使用 - address
    //=========================================
    address public vaultRouter;
    address public positionAddMgr;
    address public positionSubMgr;
    address public orderMgr;
    address public marketRouter; // 权限判断,callback
    //=========================================
    //          本合约内部使用 - vars
    //=========================================
    // bool public initialized = false;
    string public name;
    address[] public plugins;
    uint256 public constant pluginGasLimit = 666666; // 66w
    // ==================
    //  不确定是否要删
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
