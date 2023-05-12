// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import "../fee/interfaces/IFeeRouter.sol";
// import "../oracle/interfaces/IPrice.sol";
// import "../market/interfaces/IMarket.sol";
// import "../vault/interfaces/IVaultRouter.sol";
// import "../position/PositionStruct.sol";
// import "../position/PositionStore.sol";

// contract PositionBookMocker {
//     using SafeMath for uint256;
//     using SignedSafeMath for int256;
//     using Position for Position.Props;

//     address public oracle; // oracle contract
//     address public feeRouter;
//     address public positionMarket;

//     PositionStore public longStore;
//     PositionStore public shortStore;

//     constructor() {
//         longStore = new PositionStore();
//         shortStore = new PositionStore();
//     }

//     function setOracle(address _oracle) external {
//         require(_oracle != address(0), "invalid address");
//         oracle = _oracle;
//     }

//     function setFeeRouter(address _router) external {
//         require(_router != address(0), "invalid address");
//         feeRouter = _router;
//     }

//     function setPositionMarket(address _positionMarket) external {
//         require(_positionMarket != address(0), "invalid address");
//         positionMarket = _positionMarket;
//     }

//     function userLongSizes(address account) external view returns (uint256) {
//         return IPositionMarket(positionMarket).userLongSizes(account);
//     }

//     function userShortSizes(address account) external view returns (uint256) {
//         return IPositionMarket(positionMarket).userShortSizes(account);
//     }

//     function marketLongSizes(address market) external view returns (uint256) {
//         return IPositionMarket(positionMarket).marketLongSizes(market);
//     }

//     function marketShortSizes(address market) external view returns (uint256) {
//         return IPositionMarket(positionMarket).marketShortSizes(market);
//     }

//     function globalLongSizes() external view returns (uint256) {
//         return IPositionMarket(positionMarket).globalLongSizes();
//     }

//     function globalShortSizes() external view returns (uint256) {
//         return IPositionMarket(positionMarket).globalShortSizes();
//     }

//     function getPositionKey(
//         address _account,
//         address _market,
//         bool _isLong
//     ) public pure returns (bytes32) {
//         return keccak256(abi.encodePacked(_account, _market, _isLong));
//     }

//     function getPositionKeys(
//         uint256 _start,
//         uint256 _end,
//         bool _isLong
//     ) external view returns (bytes32[] memory) {
//         require(_end >= _start, "PB:gpk");

//         PositionStore _store = _isLong ? longStore : shortStore;

//         return _getPositionKeys(_store, _start, _end);
//     }

//     function getPosition(
//         address _account,
//         address _market,
//         bool _isLong
//     )
//         external
//         view
//         returns (uint256, uint256, uint256, int256, uint256, bool, uint256)
//     {
//         Position.Props memory _position = _getPosition(
//             _account,
//             _market,
//             _isLong
//         );

//         bool _hasProfit;
//         uint256 _realisedPnl;

//         if (_position.size != 0) {
//             address _indexToken = IMarket(_market).indexToken();

//             (_hasProfit, _realisedPnl) = _getPNL(_position, _indexToken);
//         }

//         return (
//             _position.size,
//             _position.collateral,
//             _position.averagePrice,
//             _position.entryFundingRate,
//             _realisedPnl,
//             _hasProfit,
//             _position.lastTime
//         );
//     }

//     function getPositionByKey(
//         bytes32 _key,
//         bool _isLong
//     )
//         external
//         view
//         returns (
//             uint256,
//             uint256,
//             uint256,
//             int256,
//             uint256,
//             bool,
//             address,
//             address,
//             uint256
//         )
//     {
//         Position.Props memory _position = _getPositionByKey(_key, _isLong);

//         bool _hasProfit;
//         uint256 _realisedPnl;

//         if (_position.size != 0) {
//             address _indexToken = IMarket(_position.market).indexToken();

//             (_hasProfit, _realisedPnl) = _getPNL(_position, _indexToken);
//         }

//         return (
//             _position.size,
//             _position.collateral,
//             _position.averagePrice,
//             _position.entryFundingRate,
//             _realisedPnl,
//             _hasProfit,
//             _position.account,
//             _position.market,
//             _position.lastTime
//         );
//     }

//     function getPositionAccount(
//         bytes32 _key,
//         bool _isLong
//     ) external view returns (address) {
//         Position.Props memory _position = _getPositionByKey(_key, _isLong);
//         return _position.account;
//     }

//     function getLongPositionLen() external view returns (uint256) {
//         return PositionStore(longStore).getPositionCount();
//     }

//     function getShortPositionLen() external view returns (uint256) {
//         return PositionStore(shortStore).getPositionCount();
//     }

//     function getDeltaPNL(
//         address _account,
//         address _market,
//         uint256 _sizeDelta,
//         bool _isLong
//     ) external view returns (int256) {
//         Position.Props memory _position = _getPosition(
//             _account,
//             _market,
//             _isLong
//         );
//         if (_position.size == 0) {
//             return 0;
//         }

//         address _indexToken = IMarket(_market).indexToken();

//         (bool _hasProfit, uint256 _pnl) = _getPNL(_position, _indexToken);

//         _pnl = (_sizeDelta * _pnl) / _position.size;

//         return _hasProfit ? int256(_pnl) : -int256(_pnl);
//     }

//     function getPNL(
//         address _account,
//         address _market,
//         bool _isLong
//     ) public view returns (int256) {
//         Position.Props memory _position = _getPosition(
//             _account,
//             _market,
//             _isLong
//         );
//         if (_position.size == 0) {
//             return 0;
//         }

//         address _indexToken = IMarket(_market).indexToken();
//         (bool _hasProfit, uint256 _pnl) = _getPNL(_position, _indexToken);
//         return _hasProfit ? int256(_pnl) : -int256(_pnl);
//     }

//     function getGlobalPnl() external view returns (int256) {
//         int256 _totalPNL;
//         uint256 _len;
//         address[] memory _markets = IPositionMarket(positionMarket)
//             .getAllMarketAddress();

//         _len = _markets.length;

//         for (uint8 i = 0; i < _len; ) {
//             address _market = _markets[i];

//             _totalPNL = _totalPNL + _getGlobalPNL(_market, true);
//             _totalPNL = _totalPNL + _getGlobalPNL(_market, false);

//             unchecked {
//                 ++i;
//             }
//         }

//         return _totalPNL;
//     }

//     function getMaxIncreasePositionSize(
//         address _market,
//         address _account,
//         bool _isLong
//     ) external view returns (uint256) {
//         return 10000000;
//     }

//     function increasePosition(
//         address _account,
//         address _market,
//         uint256 _collateralDelta,
//         uint256 _sizeDelta,
//         uint256 _markPrice,
//         bool _isLong
//     ) external {
//         updateCumulativeFundingRate(_market);

//         Position.Props memory _position = _getPosition(
//             _account,
//             _market,
//             _isLong
//         );

//         if (_position.size == 0) {
//             _position.averagePrice = _markPrice;
//         }
//         if (_position.size > 0 && _sizeDelta > 0) {
//             address _indexToken = IMarket(_market).indexToken();
//             (bool _hasProfit, uint256 _pnl) = _getPNL(_position, _indexToken);

//             _position.averagePrice = _position.calAveragePrice(
//                 _sizeDelta,
//                 _markPrice,
//                 _pnl,
//                 _hasProfit
//             );
//         }

//         _position.collateral = _position.collateral.add(_collateralDelta);
//         _position.entryFundingRate = _cumulativeFundingRates(_market, _isLong);
//         _position.size = _position.size.add(_sizeDelta);
//         _position.isLong = _isLong;
//         _position.market = _market;
//         _position.account = _account;
//         _position.lastTime = block.timestamp;

//         _updatePosition(_account, _market, _isLong, _position);

//         _updateGlobal(
//             _account,
//             _market,
//             _collateralDelta,
//             _sizeDelta,
//             _markPrice,
//             _isLong,
//             true
//         );
//     }

//     function decreasePosition(
//         address _account,
//         address _market,
//         uint256 _collateralDelta,
//         uint256 _sizeDelta,
//         bool _isLong
//     ) external {
//         Position.Props memory _position = _getPosition(
//             _account,
//             _market,
//             _isLong
//         );

//         // TODO, repair valid
//         require(_position.size > 0, "position does not exist");
//         require(_position.size > _position.collateral, "position is invalid");
//         require(_position.collateral >= _collateralDelta, "invalid collateral");

//         updateCumulativeFundingRate(_market);

//         if (_position.size != _sizeDelta) {
//             _position.entryFundingRate = _cumulativeFundingRates(
//                 _market,
//                 _isLong
//             );
//             _position.size = _position.size.sub(_sizeDelta);
//             _position.collateral = _position.collateral.sub(_collateralDelta);

//             _updatePosition(_account, _market, _isLong, _position);
//         } else {
//             _delPosition(_account, _market, _isLong);
//         }

//         _updateGlobal(
//             _account,
//             _market,
//             _collateralDelta,
//             _sizeDelta,
//             0,
//             _isLong,
//             false
//         );
//     }

//     function liquidatePosition(
//         address _account,
//         address _market,
//         bool _isLong
//     ) external returns (int256, int256, uint256, uint256) {
//         Position.Props memory _position = _getPosition(
//             _account,
//             _market,
//             _isLong
//         );
//         require(_position.size > 0, "position does not exist");

//         address _indexToken = IMarket(_market).indexToken();
//         (bool _hasProfit, uint256 _realisedPnl) = _getPNL(
//             _position,
//             _indexToken
//         );

//         int256 _pnl = _hasProfit ? int256(_realisedPnl) : -int256(_realisedPnl);

//         updateCumulativeFundingRate(_market);

//         _delPosition(_account, _market, _isLong);
//         _updateGlobal(
//             _account,
//             _market,
//             _position.collateral,
//             _position.size,
//             0,
//             _isLong,
//             false
//         );

//         return (
//             _pnl,
//             _cumulativeFundingRates(_market, _isLong),
//             _position.size,
//             _position.collateral
//         );
//     }

//     function liquidatePositionByKey(bytes32 _key, bool _isLong) external {
//         Position.Props memory _position = _getPositionByKey(_key, _isLong);
//         require(_position.size > 0, "position does not exist");

//         address _market = _position.market;
//         address _account = _position.account;

//         updateCumulativeFundingRate(_market);

//         _delPosition(_account, _market, _isLong);
//         _updateGlobal(
//             _account,
//             _market,
//             _position.collateral,
//             _position.size,
//             0,
//             _isLong,
//             false
//         );
//     }

//     function isLiquidation(
//         bytes32 _key,
//         bool _isLong
//     ) external view returns (bool) {
//         return true;
//     }

//     function updateCumulativeFundingRate(address market) public {
//         IFeeRouter(feeRouter).updateCumulativeFundingRate(market);
//     }

//     function _getPosition(
//         address _account,
//         address _market,
//         bool _isLong
//     ) private view returns (Position.Props memory) {
//         // TODO
//         bytes32 _key = keccak256(abi.encodePacked(_account, _market, _isLong));

//         PositionStore _store = _isLong ? longStore : shortStore;

//         return PositionStore(_store).get(_key);
//     }

//     function _getGlobalPosition(
//         address _market,
//         bool _isLong
//     ) private view returns (Position.Props memory) {
//         bytes32 _key = Position.getPositionKey(address(0), _market, _isLong);
//         return IPositionMarket(positionMarket).globalPositions(_key);
//     }

//     function _getPositionByKey(
//         bytes32 _key,
//         bool _isLong
//     ) private view returns (Position.Props memory) {
//         PositionStore _store = _isLong ? longStore : shortStore;
//         return PositionStore(_store).get(_key);
//     }

//     function _getPositionKeys(
//         PositionStore _store,
//         uint256 _start,
//         uint256 _end
//     ) private view returns (bytes32[] memory) {
//         uint256 _len = _store.getPositionCount();
//         if (_len == 0) {
//             return new bytes32[](0);
//         }

//         if (_end > _len) {
//             _end = _len;
//         }
//         return PositionStore(_store).getPositionKeys(_start, _end);
//     }

//     function _getPNL(
//         Position.Props memory _position,
//         address _indexToken
//     ) private view returns (bool, uint256) {
//         uint256 _price = _getPrice(_indexToken, _position.isLong);

//         uint256 _priceDelta = _position.averagePrice > _price
//             ? _position.averagePrice.sub(_price)
//             : _price.sub(_position.averagePrice);

//         uint256 _realisedPnl = _position.size.mul(_priceDelta).div(
//             _position.averagePrice
//         );

//         bool _hasProfit;

//         if (_position.isLong) {
//             _hasProfit = _price > _position.averagePrice;
//         } else {
//             _hasProfit = _position.averagePrice > _price;
//         }

//         /*
//             // if the minProfitTime has passed then there will be no min profit threshold
//             // the min profit threshold helps to prevent front-running issues
//             uint256 _minBPS = block.timestamp > _position.lastTime.add(minProfitTime) ? 0 : minProfitBasisPoints[_market];
//             if (_hasProfit && _realisedPnl.mul(BASIS_POINTS_DIVISOR) <= _position.size.mul(minBPS)) {
//                 _realisedPnl = 0;
//             }
//         */

//         return (_hasProfit, _realisedPnl);
//     }

//     function _getGlobalPNL(
//         address _market,
//         bool _isLong
//     ) private view returns (int256) {
//         Position.Props memory _position = _getGlobalPosition(_market, _isLong);

//         if (_position.size == 0) {
//             return 0;
//         }

//         address _indexToken = IMarket(_market).indexToken();
//         (bool _hasProfit, uint256 _pnl) = _getPNL(_position, _indexToken);

//         uint256 _formatPNL = (_pnl / (10 ** 6)) * (10 ** 18);

//         return _hasProfit ? int256(_formatPNL) : -int256(_formatPNL);
//     }

//     function _getPrice(
//         address _indexToken,
//         bool _isLong
//     ) private view returns (uint256) {
//         return 100;
//     }

//     function _cumulativeFundingRates(
//         address _market,
//         bool _isLong
//     ) private view returns (int256) {
//         return IFeeRouter(feeRouter).cumulativeFundingRates(_market, _isLong);
//     }

//     function _updateGlobal(
//         address _account,
//         address _market,
//         uint256 _collateralDelta,
//         uint256 _sizeDelta,
//         uint256 _markPrice,
//         bool _isLong,
//         bool _isOpen
//     ) private {
//         if (_isOpen) {
//             uint256 _averagePrice = _getGlobalAveragePrice(
//                 _market,
//                 _sizeDelta,
//                 _markPrice,
//                 _isLong
//             );
//             IPositionMarket(positionMarket).increaseGlobalPosition(
//                 _account,
//                 _market,
//                 _collateralDelta,
//                 _sizeDelta,
//                 _averagePrice,
//                 _isLong
//             );
//             return;
//         }

//         IPositionMarket(positionMarket).decreaseGlobalPosition(
//             _account,
//             _market,
//             _collateralDelta,
//             _sizeDelta,
//             _isLong
//         );
//     }

//     function _getGlobalAveragePrice(
//         address _market,
//         uint256 _sizeDelta,
//         uint256 _markPrice,
//         bool _isLong
//     ) private view returns (uint256) {
//         Position.Props memory _position = _getGlobalPosition(_market, _isLong);

//         if (_position.size == 0) {
//             return _markPrice;
//         }
//         if (_position.size > 0 && _sizeDelta > 0) {
//             address _indexToken = IMarket(_market).indexToken();
//             (bool _hasProfit, uint256 _pnl) = _getPNL(_position, _indexToken);
//             _position.averagePrice = _position.calAveragePrice(
//                 _sizeDelta,
//                 _markPrice,
//                 _pnl,
//                 _hasProfit
//             );
//         }

//         return _position.averagePrice;
//     }

//     function _updatePosition(
//         address _account,
//         address _market,
//         bool _isLong,
//         Position.Props memory _position
//     ) private {
//         PositionStore _store = _isLong ? longStore : shortStore;
//         // TODO
//         bytes32 _key = keccak256(abi.encodePacked(_account, _market, _isLong));
//         PositionStore(_store).set(_key, _position);
//     }

//     function _delPosition(
//         address _account,
//         address _market,
//         bool _isLong
//     ) private {
//         PositionStore _store = _isLong ? longStore : shortStore;
//         // TODO
//         bytes32 _key = keccak256(abi.encodePacked(_account, _market, _isLong));

//         PositionStore(_store).remove(_key);
//     }
// }
