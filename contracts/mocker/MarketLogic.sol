// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../order/interface/IOrderBook.sol";
import {IPrice} from "../oracle/interfaces/IPrice.sol";
import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import {Calc} from "../utils/Calc.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {IVaultRouter} from "../vault/interfaces/IVaultRouter.sol";
import "../market/MarketStorage.sol";
import {IMarketValid} from "../market/interfaces/IMarketValid.sol";
import {MarketLib} from "../market/MarketLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../market/interfaces/IMarketCallBackIntl.sol";
import {IReferral} from "../referral/interfaces/IReferral.sol";
import "./../position/PositionStruct.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TransferHelper, IERC20Decimals} from "./../utils/TransferHelper.sol";
import "hardhat/console.sol";
import {IVaultRouter} from "./../vault/interfaces/IVaultRouter.sol";
import "../market/interfaces/IMarketRouter.sol";

contract MarketLogic is ReentrancyGuard, AccessControl {
    using Calc for uint256;
    using Calc for int256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using Order for Order.Props;
    using MarketLib for uint16;
    using MarketLib for uint256;
    using MarketDataTypes for MarketDataTypes.UpdateOrderInputs;
    using MarketDataTypes for MarketDataTypes.UpdatePositionInputs;
    using MarketDataTypes for int256[];

    address public marketValid;
    address public globalValid;
    address public indexToken;
    IPositionBook public positionBook;
    address public collateralToken;
    IOrderBook public orderBookLong;
    IOrderBook public orderBookShort;

    mapping(bool => mapping(bool => IOrderStore)) orderStores;

    bytes32 internal constant ROLE_CONTROLLER = keccak256("ROLE_CONTROLLER");
    enum CancelReason {
        Padding,
        Liquidation,
        PositionClosed,
        Executed,
        TpAndSlExecuted,
        Canceled,
        SysCancel, //invalid order
        PartialLiquidation
    }

    function orderStore(
        bool isLong,
        bool isOpen
    ) internal view returns (IOrderStore) {
        return orderStores[isLong][isOpen];
    }

    IFeeRouter public feeRouter;
    address public priceFeed; // 内部使用
    address public positionStoreLong;
    address public positionStoreShort;

    //----
    // long positionStore contract address
    // IPositionStore public longStore;
    // // short positionStore contract address
    // IPositionStore public shortStore;

    //=========================================
    //          本合约内部使用 - address
    //=========================================
    address public vaultRouter;
    address public feeVault;
    //address public vault;
    address public positionAddMgr;
    address public positionSubMgr;
    address public orderMgr;
    address public factory;
    address public marketRouter; // 权限判断,callback
    //=========================================
    //          本合约内部使用 - vars
    //=========================================
    bool public initialized = false;
    string public name;
    address[] public plugins;
    uint256 public constant pluginGasLimit = 666666; // 66w
    // ==================
    //  不确定是否要删
    uint8 public collateralTokenDigits;

    //==============================================
    //        初始化
    //==============================================
    modifier initializeLock() {
        require(false == initialized, "initialized");
        _;
        initialized = true;
    }

    function initialize(
        address[] memory addrs,
        string memory _name
    ) external initializeLock {
        name = _name;
        //==================================
        positionBook = IPositionBook(addrs[0]);
        orderBookLong = IOrderBook(addrs[1]);
        orderBookShort = IOrderBook(addrs[2]);
        marketValid = addrs[3];
        priceFeed = addrs[4];
        positionSubMgr = addrs[5];
        positionAddMgr = addrs[6];
        indexToken = addrs[7];
        feeRouter = IFeeRouter(addrs[8]);
        marketRouter = addrs[9];
        vaultRouter = addrs[10];
        collateralToken = addrs[11];
        globalValid = addrs[12];
        orderMgr = addrs[13];
        //==================================
        orderStores[true][true] = orderBookLong.openStore();
        orderStores[true][false] = orderBookLong.closeStore();
        orderStores[false][true] = orderBookShort.openStore();
        orderStores[false][false] = orderBookShort.closeStore();
        collateralTokenDigits = IERC20Decimals(collateralToken).decimals();
        //todo
        // feeVault = feeRouter.feeVault();
        positionStoreLong = positionBook.longStore();
        positionStoreShort = positionBook.shortStore();
        plugins.push(marketRouter);
        //==================================
    }

    function addPlugin(address _addr) external {
        // require if address implements interface
        //TODO
        //MarketOrderCallBackIntl(_addr);
        plugins.push(_addr);
    }

    constructor(address _f) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _f);
    }

    function grantAndRevoke(bytes32 role, address account) external {
        grantRole(role, account);
        // revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function decreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _vars
    ) external {
        //require(_vars.isValid());
        require(
            !_vars._isExec && 0 == _vars._fromOrder,
            "PositionSubMgr:wrong isexec/fromorder"
        );
        if (_vars._slippage == 0) _vars._slippage = 30;
        if (_vars._sizeDelta > 0)
            _vars._oraclePrice = _getClosePrice(!_vars._isLong);
        Position.Props memory _position = positionBook.getPosition(
            _vars._account,
            _vars._oraclePrice,
            _vars._isLong
        );
        if (_vars._sizeDelta > 0)
            _vars.collateralDelta = MarketLib.getDecreaseDeltaCollateral(
                _vars.isKeepLev(),
                _position.size,
                _vars._sizeDelta,
                _position.collateral
            );
        _decreasePosition(_vars, _position);
    }

    function liquidatePositions(
        address[] memory accounts,
        bool _isLong
    ) external {
        // TODO ac
        uint256 _len = accounts.length;
        for (uint256 i; i < _len; ) {
            address _account = accounts[i];
            _liquidatePosition(_account, _isLong);
            unchecked {
                ++i;
            }
        }
    }

    function _liquidatePosition(address _account, bool _isLong) private {
        MarketDataTypes.UpdatePositionInputs memory _vars;
        _vars.initialize(false);
        _vars._oraclePrice = _getClosePrice(_isLong);
        _vars._account = _account;
        console.log("_liquidatePosition>>>");
        console.log(_vars._oraclePrice);

        _vars._isExec = true;
        _vars._isLong = _isLong;
        Position.Props memory _position = positionBook.getPosition(
            _account,
            _vars._oraclePrice,
            _isLong
        );
        _vars._sizeDelta = _position.size;
        _vars.collateralDelta = _position.collateral;
        _vars._market = address(this);

        // int256[] memory _fees = feeRouter.getFees(_vars, _position);
        // _vars.liqState = _valid().validateLiquidation(
        //     _position.realisedPnl,
        //     _fees[1] + _fees[2],
        //     _fees[4],
        //     int256(_position.collateral),
        //     _position.size,
        //     false
        // );
        // require(_vars.liqState > 0, "PositionSubMgr:should'nt liq");
        _vars.liqState = uint8(
            _valid().isLiquidate(
                _account,
                address(this),
                _isLong,
                positionBook,
                feeRouter,
                _getClosePrice(_isLong)
            )
        );
        require(_vars.liqState > 0, "PositionSubMgr:should'nt liq");
        _decreasePosition(_vars, _position);
        //todo
        // feeRouter.collectFees(account, token, types, fees);
    }

    // stack too deep
    function _decreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _params,
        Position.Props memory _position
    ) private {
        if (_position.size == 0 || _params._account == address(0)) return;
        MarketLib._updateCumulativeFundingRate(positionBook, feeRouter);
        bool isCloseAll = _position.size == _params._sizeDelta;

        if (isCloseAll) {
            CancelReason reason = CancelReason.PositionClosed;
            if (_params.liqState == 1) reason = CancelReason.Liquidation;
            else if (_params.liqState == 2)
                reason = CancelReason.PartialLiquidation;

            IOrderBook ob = _params._isLong ? orderBookLong : orderBookShort;
            Order.Props[] memory _ordersDeleted = ob.removeByAccount(
                false,
                _params._account
            );

            for (uint i = 0; i < _ordersDeleted.length; i++) {
                // TODO 潜在风险, gas费会不会超出
                Order.Props memory _orderDeleted = _ordersDeleted[i];
                if (_orderDeleted.account == address(0)) {
                    continue;
                }
                _params.execNum += 1;
                MarketLib.afterDeleteOrder(
                    MarketOrderCallBackIntl.DeleteOrderEvent(
                        _orderDeleted,
                        _params,
                        uint8(reason),
                        0
                    ),
                    pluginGasLimit,
                    plugins,
                    collateralToken,
                    address(this)
                );
            }
        }
        _params._market = address(this);

        console.log("execNum>>>");
        console.log(_params.execNum);

        int256[] memory _fees = feeRouter.getFees(_params, _position);

        // 验证保证金
        IMarketValid mv = _valid();
        if (_params._sizeDelta == 0) {
            mv.validCollateralDelta(
                4,
                _position.collateral,
                _params.collateralDelta,
                _position.size,
                0,
                0
            );
        } else {
            mv.validPosition(_params, _position, _fees);
        }

        int256 dPnl;
        if (_params._sizeDelta > 0) {
            dPnl = positionBook.getPNL(
                _params._account,
                _params._sizeDelta,
                _params._oraclePrice,
                _params._isLong
            );
        }
        _position.realisedPnl = dPnl;

        int256 feesTotal = _fees.totoalFees();

        (uint256 newCollateralUnsigned, ) = _decreaseTransaction(
            _params,
            _position,
            dPnl,
            feesTotal
        );

        console.log("<><><><><><><");
        console.log("_params.collateral delta", _params.collateralDelta); //9.9
        console.log((uint256(feesTotal) * 100) / _position.size); //0

        console.log(
            isCloseAll
                ? _position.collateral
                : (_position.collateral - newCollateralUnsigned)
        ); //198

        int256 _nowFundRate = feeRouter.cumulativeFundingRates(
            address(this),
            _params._isLong
        );
        // 5. 调用position.sol, 减仓
        IVaultRouter(vaultRouter).repayToVault(
            TransferHelper.formatCollateral(
                _params._sizeDelta,
                IERC20Decimals(collateralToken).decimals()
            )
        );
        positionBook.decreasePosition(
            _params._account,
            isCloseAll
                ? _position.collateral
                : (_position.collateral - newCollateralUnsigned),
            _params._sizeDelta,
            _nowFundRate,
            _params._isLong
        );
        //20-99
        //
        if (_params.liqState == 0 && _params._sizeDelta != _position.size)
            validLiq(_params._account, _params._isLong);

        //===================================
        feeRouter.collectFees(_params._account, collateralToken, _fees);

        MarketLib.afterUpdatePosition(
            MarketPositionCallBackIntl.UpdatePositionEvent(
                _params,
                _position,
                _fees,
                collateralToken,
                indexToken,
                int256(
                    isCloseAll
                        ? _position.collateral
                        : (_position.collateral - newCollateralUnsigned)
                )
            ),
            pluginGasLimit,
            plugins,
            collateralToken,
            address(this)
        );
    }

    function _transferToVault(
        IERC20 _collateralTokenERC20,
        uint256 _amount
    ) private {
        _amount = TransferHelper.formatCollateral(
            _amount,
            collateralTokenDigits
        );
        _collateralTokenERC20.approve(vaultRouter, _amount);
        IVaultRouter(vaultRouter).transferToVault(address(this), _amount);
    }

    /**
     * 减仓的时候资金操作
     */
    function _decreaseTransaction(
        MarketDataTypes.UpdatePositionInputs memory _params,
        Position.Props memory _position,
        int256 dPNL,
        int256 fees
    ) private returns (uint256 newCollateralUnsigned, int256 transToUser) {
        int256 newCollateral = _position.collateral.toInt256(); // 19800000000000000000
        bool isCloseAll = _position.size == _params._sizeDelta;
        if (isCloseAll) {
            _params.collateralDelta = _position.collateral; //TODO remove this line?
        }
        address _collateralToken = collateralToken;
        IERC20 _collateralTokenERC20 = IERC20(_collateralToken);
        int256 totalTransferOut = 0;
        //2.费用转账
        if (fees < 0) {
            // deprecated!!!!
            /* transToUser -= fees; //-5
            MarketLib.feeWithdraw(
                collateralToken,
                address(this),
                fees,
                collateralTokenDigits,
                address(feeRouter)
            ); */
        } else {
            if (
                (_params.liqState > 0 || isCloseAll) &&
                fees > _position.collateral.toInt256()
            ) {
                transToUser += _position.collateral.toInt256(); //-5
                uint256 amount = TransferHelper.formatCollateral(
                    uint256(_position.collateral),
                    IERC20Decimals(collateralToken).decimals()
                );
                IERC20(collateralToken).approve(address(feeRouter), amount);
                return (newCollateralUnsigned, transToUser);
            } else {
                transToUser -= fees; //-5
                totalTransferOut -= fees;
                uint256 amount = TransferHelper.formatCollateral(
                    uint256(fees),
                    IERC20Decimals(collateralToken).decimals()
                );
                IERC20(collateralToken).approve(address(feeRouter), amount);
            }
        }

        //2.转账pnl
        if (dPNL > 0) {
            transToUser += dPNL; //-5-100
            MarketLib.vaultWithdraw(
                collateralToken,
                address(this),
                dPNL,
                collateralTokenDigits,
                vaultRouter
            );
        } else if (dPNL < 0) {
            if (
                (_params.liqState > 0 || isCloseAll) &&
                dPNL + _position.collateral.toInt256() - fees < 0
            ) {
                // 穿仓
                transToUser += _position.collateral.toInt256(); //-5-100
                _transferToVault(
                    _collateralTokenERC20,
                    uint256(_position.collateral.toInt256() - fees)
                );
                return (newCollateralUnsigned, transToUser);
            } else if (dPNL + _params.collateralDelta.toInt256() < 0) {
                transToUser = 0; //-5-100
                if (_position.collateral.toInt256() + dPNL - fees > 0) {
                    newCollateralUnsigned = (_position.collateral.toInt256() +
                        dPNL -
                        fees).toUint256();
                } else {
                    newCollateralUnsigned = 0;
                }

                _transferToVault(
                    _collateralTokenERC20,
                    newCollateralUnsigned - uint256(_params.collateralDelta)
                );
                return (newCollateralUnsigned, transToUser);
            } else {
                transToUser += dPNL; //-5-100
                totalTransferOut += dPNL;
                _transferToVault(_collateralTokenERC20, uint256(dPNL * -1));
            }
        }

        //3.转账抵押品
        transToUser += _params.collateralDelta.toInt256(); //-5-100+0
        if (transToUser > 0) {
            newCollateral -= _params.collateralDelta.toInt256();
            TransferHelper.transferOut(
                collateralToken,
                _params._account,
                uint256(transToUser)
            );
        } else {
            newCollateral += totalTransferOut;
            transToUser = 0;
        }
        if (newCollateral > 0) {
            newCollateralUnsigned = newCollateral.toUint256();
        } else {
            newCollateralUnsigned = 0;
        }
    }

    function decreasePositionFromOrder(
        Order.Props memory order,
        MarketDataTypes.UpdatePositionInputs memory _params
    ) private {
        Position.Props memory _position = positionBook.getPosition(
            order.account,
            0,
            _params._isLong
        );

        _params._oraclePrice = _getClosePrice(_params._isLong);
        console.log("_oraclePrice>>>>>>>");
        console.log(_params._oraclePrice);

        // 先删掉要执行的订单
        Order.Props[] memory ods = (
            _params._isLong ? orderBookLong : orderBookShort
        ).remove(order.getKey(), false);
        require(ods[0].account != address(0), "order account is zero");

        // 遍历要删除的订单, 并且emit事件
        for (uint i = 0; i < ods.length; i++) {
            Order.Props memory od = ods[i];
            if (address(0) == od.account) continue;
            MarketLib.afterDeleteOrder(
                MarketOrderCallBackIntl.DeleteOrderEvent(
                    od,
                    _params,
                    uint8(
                        i == 0
                            ? CancelReason.Executed
                            : CancelReason.TpAndSlExecuted
                    ), // Executed, TpAndSlExecuted, 3, 4
                    i == 0
                        ? (_position.realisedPnl *
                            _params._sizeDelta.toInt256()) /
                            _position.size.toInt256()
                        : int256(0)
                ),
                pluginGasLimit,
                plugins,
                collateralToken,
                address(this)
            );
            if (i == 0) _params.execNum += 1;
            //todo
            // 不知道这行代码的意义是什么
            // require(
            //     od.isMarkPriceValid(_params._oraclePrice),
            //     "PositionSubMgr:triggerAbove"
            // );
        }

        //订单生成=>仓位
        _decreasePosition(_params, _position);
    }

    function execOrderKey(
        Order.Props memory order,
        MarketDataTypes.UpdatePositionInputs memory _params
    ) external {
        order.validOrderAccountAndID();
        //validLiq(order.account, _params._isLong);
        if (_params.isOpen) {
            _execIncreaseOrderKey(order, _params);
        } else {
            decreasePositionFromOrder(order, _params);
        }
    }

    function _getClosePrice(bool _isLong) private view returns (uint256) {
        return IPrice(priceFeed).getPrice(indexToken, !_isLong);
    }

    function increasePositionWithOrders(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) public {
        if (false == _inputs.isValid()) {
            if (_inputs._isExec) return;
            else revert("PositionAddMgr:invalid params");
        }
        _valid().validPay(_inputs.collateralDelta);

        // 如果滑点为0并且非下单增仓，则将滑点设置为30
        if (_inputs._slippage == 0 && 0 == _inputs._fromOrder) {
            _inputs._slippage = 30;
        }

        if (_inputs._sizeDelta > 0)
            _inputs._oraclePrice = getPrice(_inputs._isLong);
        Position.Props memory _position = positionBook.getPosition(
            _inputs._account,
            _inputs._sizeDelta == 0 ? 0 : _inputs._oraclePrice,
            _inputs._isLong
        );

        // 增加仓位并返回标记价格和增加的保证金
        //int256 collateralChanged =
        _increasePosition(_inputs, _position);
        // 判断是否需要创建减仓订单，不需要则直接返回标记价格
        if (
            false ==
            _shouldCreateDecreaseOrder(_inputs._account, _inputs._isLong) ||
            _inputs._sizeDelta == 0
        ) {
            return;
        }

        // 判断是否需要下止盈/止损订单
        bool placeTp = _inputs.tp() != 0 &&
            (_inputs.tp() > _inputs._price == _inputs._isLong ||
                _inputs.tp() == _inputs._price);

        bool placeSl = _inputs.sl() != 0 &&
            (_inputs._isLong == _inputs._price > _inputs.sl() ||
                _inputs._price == _inputs.sl());

        MarketDataTypes.UpdateOrderInputs[] memory _vars;
        uint256 ordersCount = placeTp && placeSl
            ? 2
            : (placeTp || placeSl ? 1 : 0);
        if (ordersCount > 0) {
            _vars = new MarketDataTypes.UpdateOrderInputs[](ordersCount);
            _vars[0] = _buildDecreaseVars(
                _inputs,
                0,
                placeTp ? _inputs.tp() : _inputs.sl(),
                placeTp
            );

            if (ordersCount == 2) {
                _vars[1] = _buildDecreaseVars(_inputs, 0, _inputs.sl(), false);
            }
        } else return;

        // 下单
        Order.Props[] memory _os = (
            _inputs._isLong ? orderBookLong : orderBookShort
        ).add(_vars);
        uint256[] memory inputs = new uint256[](0);
        for (uint i; i < _os.length; ) {
            Order.Props memory _order = _os[i];
            // 调用回调函数更新订单信息
            MarketLib.afterUpdateOrder(
                MarketDataTypes.UpdateOrderInputs({
                    _market: address(this),
                    _isLong: _inputs._isLong,
                    _oraclePrice: _inputs._oraclePrice,
                    isOpen: false,
                    isCreate: true,
                    _order: _order,
                    inputs: inputs
                }),
                pluginGasLimit,
                plugins,
                collateralToken,
                address(this)
            );
            // 下标自增
            unchecked {
                ++i;
            }
        }
    }

    function commitIncreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _params,
        int256 collD,
        int256 fr
    ) private {
        if (_params._sizeDelta == 0 && collD < 0) {
            positionBook.decreasePosition(
                _params._account,
                uint256(-collD),
                _params._sizeDelta,
                fr,
                _params._isLong
            );
        } else {
            IVaultRouter(vaultRouter).borrowFromVault(
                TransferHelper.formatCollateral(
                    _params._sizeDelta,
                    IERC20Decimals(collateralToken).decimals()
                )
            );
            positionBook.increasePosition(
                _params._account,
                collD.toUint256(),
                _params._sizeDelta,
                _params._oraclePrice,
                fr,
                _params._isLong
            );
        }
    }

    function _increasePosition(
        MarketDataTypes.UpdatePositionInputs memory _params,
        Position.Props memory _position
    ) private returns (int256 collD) {
        MarketLib._updateCumulativeFundingRate(positionBook, feeRouter); //1
        _params._market = address(this); //remove this line?
        int256[] memory _fees = feeRouter.getFees(_params, _position);
        int256 _totalfee = _fees.totoalFees();
        // console.log("total fee", uint256(_totalfee));

        if (_params._sizeDelta > 0) {
            _valid().validPosition(_params, _position, _fees);
        } else {
            _valid().validCollateralDelta(
                2,
                _position.collateral,
                _params.collateralDelta,
                _position.size,
                0,
                _totalfee
            );
        }

        int256 _fundingRate = feeRouter.cumulativeFundingRates(
            address(this),
            _params._isLong
        );
        collD = _params.collateralDelta.toInt256() - _totalfee;
        commitIncreasePosition(_params, collD, _fundingRate);
        validLiq(_params._account, _params._isLong);

        _transationsFees(_totalfee); // 手续费转账

        feeRouter.collectFees(_params._account, collateralToken, _fees);

        MarketLib.afterUpdatePosition(
            MarketPositionCallBackIntl.UpdatePositionEvent(
                _params,
                _position,
                _fees,
                collateralToken,
                indexToken,
                collD
            ),
            pluginGasLimit,
            plugins,
            collateralToken,
            address(this)
        );
    }

    function _transationsFees(int256 fees) private {
        if (fees < 0) {
            IFeeRouter(feeRouter).withdraw(
                collateralToken,
                address(this),
                uint(fees * -1)
            );
        } else if (fees > 0) {
            uint256 amount = TransferHelper.formatCollateral(
                uint(fees),
                IERC20Decimals(collateralToken).decimals()
            );
            IERC20(collateralToken).approve(address(feeRouter), amount);
        }
    }

    function _execIncreaseOrderKey(
        Order.Props memory order,
        MarketDataTypes.UpdatePositionInputs memory _params
    ) private {
        require(order.account != address(0), "PositionAddMgr:invalid account");
        IMarketRouter(marketRouter).validateIncreasePosition(_params);
        increasePositionWithOrders(_params);
        require(
            order.isMarkPriceValid(_params._oraclePrice),
            "PositionAddMgr::triggerabove"
        );
        (_params._isLong ? orderBookLong : orderBookShort).remove(
            order.getKey(),
            true
        );

        MarketLib.afterDeleteOrder(
            MarketOrderCallBackIntl.DeleteOrderEvent(
                order,
                _params,
                uint8(CancelReason.Executed),
                int256(0)
            ),
            pluginGasLimit,
            plugins,
            collateralToken,
            address(this)
        );
    }

    function validLiq(address acc, bool _isLong) private view {
        require(
            _valid().isLiquidate(
                acc,
                address(this),
                _isLong,
                positionBook,
                feeRouter,
                getPrice(!_isLong)
            ) == 0,
            "PositionAddMgr:position under liq"
        );
    }

    function _shouldCreateDecreaseOrder(
        address account,
        bool isLong
    ) private view returns (bool) {
        return
            _valid().getDecreaseOrderValidation(
                orderStore(isLong, false).orderNum(account)
            );
    }

    function _buildDecreaseVars(
        MarketDataTypes.UpdatePositionInputs memory _inputs,
        uint256 /* collateralIncreased */,
        uint256 triggerPrice,
        bool isTP
    )
        private
        view
        returns (MarketDataTypes.UpdateOrderInputs memory _createVars)
    {
        _createVars.initialize(false);
        _createVars._market = address(this);
        _createVars._isLong = _inputs._isLong;
        _createVars._oraclePrice = getPrice(!_inputs._isLong);
        _createVars.isCreate = true;
        // 这里没有from order
        // ====
        _createVars._order.setFromOrder(_inputs._fromOrder);
        _createVars._order.account = _inputs._account;
        _createVars._order.setSize(_inputs._sizeDelta);
        _createVars._order.collateral = 0; // painter说当0处理
        _createVars._order.setTriggerAbove(isTP == _inputs._isLong);
        _createVars._order.price = uint128(triggerPrice);
        _createVars._order.refCode = _inputs._refCode;
    }

    function updateOrder(
        MarketDataTypes.UpdateOrderInputs memory _vars
    ) external {
        //require(_vars.isValid(), "orderMgr:input");
        if (_vars.isOpen && _vars.isCreate) {
            _valid().validPay(_vars.pay());
        }
        if (false == _vars.isOpen)
            _vars._oraclePrice = getPrice(!_vars._isLong);

        IOrderBook ob = _vars._isLong ? orderBookLong : orderBookShort;
        if (_vars.isCreate && _vars.isOpen) {
            _valid().validIncreaseOrder(_vars, feeRouter.getOrderFees(_vars));
            // 保存
            _vars._order.collateral = _vars.pay().toUint128();
        } else if (_vars.isCreate && !_vars.isOpen) {
            Position.Props memory _position = positionBook.getPosition(
                _vars._order.account,
                _vars._oraclePrice,
                _vars._isLong
            );
            _vars._order.collateral = MarketLib
                .getDecreaseDeltaCollateral(
                    _vars._order.extra3 > 0,
                    _position.size,
                    uint256(_vars._order.size),
                    _position.collateral
                )
                .toUint128();
            // 2. 保证金的校验
            _valid().validDecreaseOrder(
                _position.collateral,
                uint256(_vars._order.collateral),
                _position.size,
                _vars._order.size,
                feeRouter.getOrderFees(_vars),
                orderStore(_vars._isLong, _vars.isOpen).orderNum(
                    _vars._order.account
                )
            );
        }

        MarketDataTypes.UpdateOrderInputs[]
            memory orderVars = new MarketDataTypes.UpdateOrderInputs[](1);
        orderVars[0] = _vars;
        _vars._order = _vars.isCreate ? ob.add(orderVars)[0] : ob.update(_vars);

        // 触发事件
        MarketLib.afterUpdateOrder(
            _vars,
            pluginGasLimit,
            plugins,
            collateralToken,
            address(this)
        );
    }

    /**
     * 被用户调用
     */
    function cancelOrderList(
        address _account,
        bool[] memory _isIncreaseList,
        uint256[] memory _orderIDList,
        bool[] memory _isLongList
    ) external /*nonReentrant*/ {
        // require(
        //     hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
        //         hasRole(ROLE_CONTROLLER, msg.sender),
        //         "OrderMgr:access control"
        // );

        require(
            _isIncreaseList.length == _orderIDList.length,
            "OrderMgr:input length"
        );
        require(
            _isLongList.length == _orderIDList.length,
            "OrderMgr:input length"
        );
        uint len = _orderIDList.length;
        uint256 collateralRefund;
        for (uint i; i < len; ) {
            Order.Props memory _or = (
                _isLongList[i] ? orderBookLong : orderBookShort
            ).remove(_account, _orderIDList[i], _isIncreaseList[i])[0];
            //=============================
            collateralRefund += _cancelOrder(
                _or,
                _isLongList[i],
                _isIncreaseList[i],
                false,
                false
            );

            unchecked {
                ++i;
            }
        }
        TransferHelper.transferOut(collateralToken, _account, collateralRefund);
    }

    function sysCancelOrder(
        bytes32[] memory _orderKey,
        bool[] memory _isLong,
        bool[] memory _isIncrease
    ) external {
        require(_orderKey.length == _isLong.length);
        require(_isIncrease.length == _isLong.length);
        for (uint i = 0; i < _orderKey.length; i++) {
            require(_orderKey[i] != bytes32(0), "OrderMgr:invalid order key");
            Order.Props[] memory exeOrders = (
                _isLong[i] ? orderBookLong : orderBookShort
            ).remove(_orderKey[i], _isIncrease[i]);
            for (uint j = 0; j < exeOrders.length; j++) {
                _cancelOrder(
                    exeOrders[j],
                    _isLong[i],
                    _isIncrease[i],
                    true,
                    true
                );
            }
        }
    }

    function _cancelOrder(
        Order.Props memory _order,
        bool _isLong, //false
        bool _isIncrease, //true
        bool _isTransferToUser, //true
        bool isExec //true
    ) internal returns (uint256 collateralRefund) {
        uint256 execFee = isExec ? feeRouter.getExecFee(address(this)) : 0;
        if (_isIncrease) {
            if (execFee > 0) {
                // TransferHelper.transferOut(collateralToken, feeVault, execFee);
                IERC20(collateralToken).approve(address(feeRouter), execFee);
                // todo
                int256[] memory _fees = new int256[](4);
                _fees[3] = int256(execFee);
                feeRouter.collectFees(_order.account, collateralToken, _fees);
            }
            if (_isTransferToUser) {
                TransferHelper.transferOut(
                    collateralToken,
                    _order.account,
                    _order.collateral - execFee
                );
            } else {
                collateralRefund = _order.collateral;
            }
        } else if (isExec) {
            //_isIncrease==false, isExec==true
            (uint256 _longSize, uint256 _shortSize) = positionBook
                .getMarketSizes();
            int256 _fundRate = feeRouter.getFundingRate(
                address(this),
                _longSize,
                _shortSize,
                _isLong
            );
            uint256 decreasedCollateral = positionBook
                .decreaseCollateralFromCancelInvalidOrder(
                    _order.account,
                    execFee,
                    _fundRate,
                    _isLong
                );
            if (decreasedCollateral >= execFee) {
                int256[] memory _fees = new int256[](4);
                _fees[3] = int256(execFee);
                IERC20(collateralToken).approve(address(feeRouter), execFee);
                feeRouter.collectFees(_order.account, collateralToken, _fees);
                //TransferHelper.transferOut(collateralToken, feeVault, execFee);
            }
        }

        MarketDataTypes.UpdatePositionInputs memory inputs;
        inputs._market = address(this);
        inputs._isLong = _isLong;
        inputs._oraclePrice = getPrice(true);
        inputs.isOpen = _isIncrease;

        MarketLib.afterDeleteOrder(
            MarketOrderCallBackIntl.DeleteOrderEvent(
                _order,
                inputs,
                uint8(isExec ? CancelReason.SysCancel : CancelReason.Canceled), //6,5
                int256(0)
            ),
            pluginGasLimit,
            plugins,
            collateralToken,
            address(this)
        );
    }

    function _valid() internal view returns (IMarketValid) {
        return IMarketValid(marketValid);
    }

    //==============================================
    //    getters & setters
    //==============================================
    function getPrice(bool _isMax) private view returns (uint256) {
        IPrice _p = IPrice(priceFeed);
        return _p.getPrice(indexToken, _isMax);
    }

    function getPositions(
        address account
    ) external view returns (Position.Props[] memory) {
        // return positionBook.getPositions(getPrice(true));
        return positionBook.getPositions(account);
    }

    function USDDecimals() external pure returns (uint8) {
        return TransferHelper.getUSDDecimals();
    }

    function getPNL() external view returns (int256 pnl) {
        uint256 p = IPrice(priceFeed).getPrice(indexToken, true);
        pnl = IPositionBook(positionBook).getMarketPNL(p);
    }
}
