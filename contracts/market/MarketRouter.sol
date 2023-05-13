// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IMarket} from "./interfaces/IMarket.sol";
import {MarketPositionCallBackIntl, MarketOrderCallBackIntl} from "./interfaces/IMarketCallBackIntl.sol";
import {MarketDataTypes} from "./MarketDataTypes.sol";

import {MarketLib} from "./MarketLib.sol";
import "../utils/EnumerableValues.sol";
import "../position/interfaces/IPositionBook.sol";
import "./interfaces/IGlobalValid.sol";
import "../vault/interfaces/IVaultRouter.sol";
import "../order/OrderLib.sol";
import "../order/OrderStruct.sol";
import {TransferHelper} from "./../utils/TransferHelper.sol";
import "../ac/Ac.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketRouter is
    MarketPositionCallBackIntl,
    MarketOrderCallBackIntl,
    Ac,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;
    using MarketDataTypes for MarketDataTypes.UpdateOrderInputs;
    using MarketDataTypes for MarketDataTypes.UpdatePositionInputs;
    using Order for Order.Props;
    using SafeERC20 for IERC20;
    mapping(address => address) pbs;

    EnumerableSet.AddressSet internal positionBooks;
    EnumerableSet.AddressSet internal markets;
    address public gv;
    address public vaultRouter;

    function getMarkets() external view returns (address[] memory) {
        return markets.values();
    }

    event UpdatePosition(
        address indexed account,
        uint256 collateralDelta,
        int256 collateralDeltaAfter,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        int256 pnl,
        int256[] fees,
        address market,
        address collateralToken,
        address indexToken,
        uint256 category,
        uint64 fromOrder
    );

      event UpdateOrder(
        address indexed account, //0
        bool isLong, //1
        bool isIncrease, //2 if false, trade type == "trigger", otherwise, type =="limit"
        uint256 orderID, //3
        address market, //4 -> market name
        uint256 size, //5
        uint collateral, //6
        uint256 triggerPrice, //7
        bool triggerAbove, // , set to bool
        uint tp, //9
        uint sl, //10
        uint128 fromOrder, //11
        bool isKeepLev //12
    );
 
    event DeleteOrder(
        address indexed account,
        bool isLong,
        bool isIncrease,
        uint256 orderID,
        address market,
        uint8 reason,
        uint256 price,
        int256 dPNL
    );

    constructor(address _f) Ac(_f) {}

    // USER ACTIONS

    /**
     * @dev Validates the inputs for increasing a position.
     * @param _inputs Inputs required to update a position.
     *     - _market: The address of the market.
     *     - _isLong: Whether the position is long or short.
     *     - _oraclePrice: The current oracle price for the market.
     *     - isOpen: Whether the position is open or closed.
     *     - _account: The address of the account.
     *     - _sizeDelta: The change in position size.
     *     - _price: The price of the position.
     *     - _slippage: The allowed slippage for the trade.
     *     - _isExec: Whether the position is being executed.
     *     - liqState: The state of liquidation.
     *     - _fromOrder: The ID of the order the position was created from.
     *     - _refCode: The reference code of the position.
     *     - collateralDelta: The change in collateral.
     *     - execNum: The number of executions.
     *     - inputs: Array of additional inputs.
     */
    function validateIncreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) public view {
        IPositionBook ipb = IPositionBook(pbs[_inputs._market]);
        GlobalDataTypes.ValidParams memory params;
        params.market = _inputs._market;
        params.sizeDelta = _inputs._sizeDelta;
        params.isLong = _inputs._isLong;
        (params.globalLongSizes, params.globalShortSizes) = getGlobalSize();
        (params.userLongSizes, params.userShortSizes) = getAccountSize(
            msg.sender
        );
        (params.marketLongSizes, params.marketShortSizes) = ipb
            .getMarketSizes();
        address _collateralToken = IMarket(_inputs._market).collateralToken();

        params.usdBalance = TransferHelper.parseVaultAsset(
            IVaultRouter(vaultRouter).getUSDBalance(),
            IERC20Metadata(_collateralToken).decimals()
        );

        require(IGlobalValid(gv).isIncreasePosition(params), "mr:gv");
    }

    /**
     * @notice Increases the size of a position on a market with the specified inputs
     * @param _inputs Inputs for updating the position
     *        _inputs._market Address of the market
     *        _inputs._isLong Whether the position is long (true) or short (false)
     *        _inputs._oraclePrice Price of the oracle for the market
     *        _inputs.isOpen Whether the position is open (true) or closed (false)
     *        _inputs._account Address of the account to increase position for
     *        _inputs._sizeDelta Amount to increase the size of the position by
     *        _inputs._price Price at which to increase the position
     *        _inputs._slippage Maximum amount of slippage allowed in the price
     *        _inputs._isExec Whether this is an execution of a previous order or not
     *        _inputs.liqState Liquidation state of the position
     *        _inputs._fromOrder ID of the order from which the position was executed
     *        _inputs._refCode Reference code for the position
     *        _inputs.collateralDelta Amount of collateral to add or remove from the position
     *        _inputs.execNum Execution number of the position
     *        _inputs.inputs Additional inputs for updating the position
     */
    function increasePosition(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) public nonReentrant {
        require(markets.contains(_inputs._market), "invalid market");
        require(_inputs.isValid(), "invalid params");
        IMarket im = IMarket(_inputs._market);

        address c = im.collateralToken();
        IERC20(c).safeTransferFrom(
            msg.sender,
            _inputs._market,
            calculateEquivalentCollateralAmount(c, _inputs.collateralDelta) // transfer in amount of collateral token
        );
        _inputs._account = msg.sender;

        validateIncreasePosition(_inputs);
        IMarket(_inputs._market).increasePositionWithOrders(_inputs);
    }

    /**
     * @dev Create/Updates an order in a market.
     * @param _vars MarketDataTypes.UpdateOrderInputs memory containing the inputs required to update the order
     * _vars._market Address of the market
     * _vars._isLong Boolean indicating if the order is long
     * _vars._oraclePrice Price of the oracle
     * _vars.isOpen Boolean indicating if the order is open
     * _vars.isCreate Boolean indicating if the order is being created
     * _vars._order Order.Props containing the properties of the order to be updated
     * _vars.inputs Array of additional inputs required to update the order
     */
    function updateOrder(
        MarketDataTypes.UpdateOrderInputs memory _vars
    ) external nonReentrant {
        require(markets.contains(_vars._market), "invalid market");
        require(_vars.isValid(), "invalid params");
        _vars._order.account = msg.sender;
        if (_vars.isOpen && _vars.isCreate) {
            address c = IMarket(_vars._market).collateralToken();
            IERC20(c).safeTransferFrom(
                msg.sender,
                _vars._market,
                calculateEquivalentCollateralAmount(c, _vars.pay()) // transfer in amount of collateral token
            );
        }
        IMarket(_vars._market).updateOrder(_vars);
    }

    /**
     * @dev Function to decrease the position in the market
     * @param _vars Struct containing the inputs to update the position
     *  _vars._market Address of the market
     *  _vars._isLong Boolean indicating the direction of the position
     *  _vars._oraclePrice Price of the oracle used for the market
     *  _vars.isOpen Boolean indicating if the position is open or not
     *  _vars._account Address of the account associated with the position
     *  _vars._sizeDelta Change in size of the position
     *  _vars._price Price of the position
     *  _vars._slippage Maximum price slippage allowed
     *  _vars._isExec Boolean indicating if the order has been executed
     *  _vars.liqState Liquidation state of the position
     *  _vars._fromOrder Order ID from which the position is being decreased
     *  _vars._refCode Reference code associated with the position
     *  _vars.collateralDelta Change in the collateral associated with the position
     *  _vars.execNum Number of times the order has been executed
     *  _vars.inputs Array of additional inputs
     */
    function decreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _vars
    ) external nonReentrant {
        require(markets.contains(_vars._market), "invalid market");
        require(_vars.isValid(), "invalid params");
        _vars._account = msg.sender;
        IMarket(_vars._market).decreasePosition(_vars);
    }

    /**
     * @dev Function to cancel a list of orders in a market
     * @param _markets Addresses of the market
     * @param _isIncreaseList Array of boolean values indicating if the orders are increase orders or not
     * @param _orderIDList Array of order IDs to be canceled
     * @param _isLongList Array of boolean values indicating the direction of the orders
     */
    function cancelOrderList(
        address[] memory _markets,
        bool[] memory _isIncreaseList,
        uint256[] memory _orderIDList,
        bool[] memory _isLongList
    ) external nonReentrant {
        require(
            _markets.length == _isIncreaseList.length &&
                _isIncreaseList.length == _orderIDList.length &&
                _orderIDList.length == _isLongList.length,
            "Array lengths do not match"
        );

        bool[] memory ppp = new bool[](1);
        uint256[] memory ppp2 = new uint256[](1);
        bool[] memory ppp3 = new bool[](1);

        for (uint i = 0; i < _markets.length; i++) {
            require(markets.contains(_markets[i]), "invalid market");
            // Check if any pair of values in the four arrays is the same
            for (uint j = i + 1; j < _markets.length; j++) {
                if (
                    _markets[i] == _markets[j] &&
                    _isIncreaseList[i] == _isIncreaseList[j] &&
                    _orderIDList[i] == _orderIDList[j] &&
                    _isLongList[i] == _isLongList[j]
                ) {
                    revert("Duplicate order found");
                }
            }
            ppp[0] = _isIncreaseList[i];
            ppp2[0] = _orderIDList[i];
            ppp3[0] = _isLongList[i];
            IMarket(_markets[i]).cancelOrderList(msg.sender, ppp, ppp2, ppp3);
        }
    }

    /**
     * @dev Calculates the equivalent collateral amount in USDei based on the collateral token amount.
     * @param _collateralToken Address of the collateral token used for the calculation.
     * @param _collateralAmount The amount of the collateral token used for the calculation.
     * @return The equivalent collateral amount in USDei.
     */
    function calculateEquivalentCollateralAmount(
        address _collateralToken,
        uint256 _collateralAmount
    ) private view returns (uint256) {
        uint8 d = IERC20Metadata(_collateralToken).decimals();
        return TransferHelper.formatCollateral(_collateralAmount, d);
    }

    /**
     * @dev Function to get the global profit and loss across all markets
     * @return pnl Total profit and loss across all markets
     */
    function getGlobalPNL() external view returns (int256 pnl) {
        for (uint i = 0; i < markets.values().length; i++) {
            address m = markets.at(i);
            int256 a = IMarket(m).getPNL();
            pnl += a;
        }
    }

    /**
     * @dev Function to get the global sizes of long and short positions in all position books
     * @return sizesLong Total size of long positions
     * @return sizesShort Total size of short positions
     */
    function getGlobalSize()
        public
        view
        returns (uint256 sizesLong, uint256 sizesShort)
    {
        for (uint i = 0; i < positionBooks.values().length; i++) {
            address pb = positionBooks.at(i);
            (uint256 l, uint256 s) = IPositionBook(pb).getMarketSizes();
            sizesLong += l;
            sizesShort += s;
        }
    }

    /**
     * @dev Function to get the sizes of long and short positions for the caller across all position books
     * @return sizesL Total size of long positions
     * @return sizesS Total size of short positions
     */
    function getAccountSize(
        address account
    ) public view returns (uint256 sizesL, uint256 sizesS) {
        for (uint i = 0; i < positionBooks.values().length; i++) {
            address pb = positionBooks.at(i);
            (uint256 l, uint256 s) = IPositionBook(pb).getAccountSize(account);
            sizesL += l;
            sizesS += s;
        }
    }

    // INIT & SETTER

    function initialize(address _gv, address vr) external initializeLock {
        gv = _gv;
        vaultRouter = vr;
    }

    function updatePositionBook(
        address newA
    ) external onlyRole(MARKET_MGR_ROLE) {
        address _market = msg.sender;
        require(markets.contains(msg.sender), "invalid market");
        positionBooks.remove(address(IMarket(_market).positionBook()));

        address _positionBook = address(IMarket(_market).positionBook());
        positionBooks.remove(_positionBook);
        positionBooks.add(newA);
        pbs[_market] = newA;
    }

    function addMarket(address _market) external onlyRole(MARKET_MGR_ROLE) {
        address _positionBook = address(IMarket(_market).positionBook());

        markets.add(_market);
        positionBooks.add(_positionBook);
        pbs[_market] = _positionBook;
    }

    function removeMarket(address _market) external onlyRole(MARKET_MGR_ROLE) {
        address _positionBook = address(IMarket(_market).positionBook());

        markets.remove(_market);
        positionBooks.remove(_positionBook);
        pbs[_market] = address(0);
    }

    // ====================================
    // CALLBACK
    // ====================================
    function updatePositionCallback(
        MarketPositionCallBackIntl.UpdatePositionEvent memory _event
    ) external override {
        require(_event.inputs._market == msg.sender, "invalid sender");
        require(markets.contains(msg.sender), "invalid market");

        uint8 category = 1;
        if (_event.inputs.isOpen) {
            if (_event.inputs._sizeDelta == 0) {
                category = 2;
            } else {
                category = 0;
            }
        } else if (_event.inputs.liqState == 1) category = 4;
        else if (_event.inputs.liqState == 2) category = 4;
        else if (_event.inputs._sizeDelta == 0) category = 3;

        emit UpdatePosition(
            _event.inputs._account,
            _event.inputs.collateralDelta,
            _event.collateralDeltaAfter,
            _event.inputs._sizeDelta,
            _event.inputs._isLong,
            _event.inputs._oraclePrice,
            _event.position.realisedPnl,
            _event.fees, 
            _event.inputs._market,
            _event.collateralToken,
            _event.indexToken,
            category,
            _event.inputs._fromOrder
        );
    }

    function updateOrderCallback(
        MarketDataTypes.UpdateOrderInputs memory _event
    ) external override {
        require(_event._market == msg.sender, "invalid sender");
        require(markets.contains(msg.sender), "invalid market");
        emit UpdateOrder(
            _event._order.account,
            _event._isLong,
            _event.isOpen,
            _event._order.orderID,
            _event._market,
            _event._order.size,
            _event._order.collateral,
            _event._order.price,
            _event._order.getTriggerAbove(),
            _event.isOpen ? _event._order.getTakeprofit() : 0,
            _event.isOpen ? _event._order.getStoploss() : 0,
            _event._order.extra0,
            _event._order.getIsKeepLev()
        );
    }

    function deleteOrderCallback(DeleteOrderEvent memory e) external override {
        require(e.inputs._market == msg.sender, "invalid sender");
        require(markets.contains(msg.sender), "invalid market");
        emit DeleteOrder(
            e.order.account,
            e.inputs._isLong,
            e.inputs.isOpen,
            e.order.orderID,
            e.inputs._market,
            e.reason,
            e.inputs._oraclePrice,
            e.dPNL
        );
    }
}
