// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./PositionStruct.sol";
import "./PositionStore.sol";
import "../ac/Ac.sol";

contract PositionBook is Ac {
    using Position for Position.Props;

    // market contract address
    address public market;
    // long positionStore contract address
    PositionStore public longStore;
    // short positionStore contract address
    PositionStore public shortStore;

    constructor(address factoty) Ac(factoty) {
        longStore = new PositionStore(factoty, true);
        shortStore = new PositionStore(factoty, false);

        _grantRole(MANAGER_ROLE, msg.sender);
    }

    function initialize(address marketAddr) external initializeLock {
        require(marketAddr != address(0), "invalid market address");
        market = marketAddr;

        _grantRole(ROLE_CONTROLLER, marketAddr);
    }

    /**
     * @dev Returns the total size of the long and short positions in the market.
     * @return A tuple containing two unsigned integers representing the total size of the long and short positions, respectively.
     * The first element of the tuple is the size of the long positions and the second element is the size of the short positions.
     * Note that this function can be called externally and does not modify the state of the contract.
     */
    function getMarketSizes() external view returns (uint256, uint256) {
        return (longStore.globalSize(), shortStore.globalSize());
    }

    function getAccountSize(
        address account
    ) external view returns (uint256, uint256) {
        Position.Props memory _longPosition = _getPosition(account, true);
        Position.Props memory _shortPosition = _getPosition(account, false);

        return (_longPosition.size, _shortPosition.size);
    }

    function getPosition(
        address account,
        uint256 markPrice,
        bool isLong
    ) external view returns (Position.Props memory) {
        Position.Props memory _position = _getPositionData(
            account,
            markPrice,
            isLong
        );
        return _position;
    }

    function getPositions(
        address account
    ) external view returns (Position.Props[] memory) {
        Position.Props memory _long = _getPositionData(account, 0, true);
        Position.Props memory _short = _getPositionData(account, 0, false);

        uint256 _index = 0;
        if (_long.size > 0) {
            _index++;
        }
        if (_short.size > 0) {
            _index++;
        }

        Position.Props[] memory _result = new Position.Props[](_index);
        if (_index > 0) {
            _index = 0;
            if (_long.size > 0) {
                _result[_index] = _long;
                _index++;
            }
            if (_short.size > 0) {
                _result[_index] = _short;
            }
        }
        return _result;
    }

    function getPositionKeys(
        uint256 start,
        uint256 end,
        bool isLong
    ) external view returns (address[] memory) {
        require(end >= start, "positionBook: invalid range params");

        PositionStore _store = isLong ? longStore : shortStore;
        return _getPositionKeys(_store, start, end);
    }

    function getPositionCount(bool isLong) external view returns (uint256) {
        PositionStore _store = isLong ? longStore : shortStore;
        return _store.getPositionCount();
    }

    function getPNL(
        address account,
        uint256 sizeDelta,
        uint256 markPrice,
        bool isLong
    ) external view returns (int256) {
        Position.Props memory _position = _getPosition(account, isLong);
        if (_position.size == 0) {
            return 0;
        }

        (bool _hasProfit, uint256 _pnl) = _getPNL(_position, markPrice);

        if (sizeDelta != 0) {
            _pnl = (sizeDelta * _pnl) / _position.size;
        }

        return _hasProfit ? int256(_pnl) : -int256(_pnl);
    }

    function getMarketPNL(uint256 markPrice) external view returns (int256) {
        int256 _totalPNL = _getMarketPNL(markPrice, true);
        _totalPNL += _getMarketPNL(markPrice, false);

        return _totalPNL;
    }

    function increasePosition(
        address account,
        uint256 collateralDelta,
        uint256 sizeDelta,
        uint256 markPrice,
        int256 fundingRate,
        bool isLong
    ) external onlyController returns (Position.Props memory result) {
        Position.Props memory _position = _getPosition(account, isLong);

        if (_position.size == 0) {
            _position.averagePrice = markPrice;
        }
        if (_position.size > 0 && sizeDelta > 0) {
            (bool _hasProfit, uint256 _realisedPnl) = _getPNL(
                _position,
                markPrice
            );

            _position.averagePrice = _position.calAveragePrice(
                sizeDelta,
                markPrice,
                _realisedPnl,
                _hasProfit
            );

            int256 _pnl = _hasProfit
                ? int256(_realisedPnl)
                : -int256(_realisedPnl);

            result.realisedPnl = _pnl;
            result.averagePrice = _position.averagePrice;
        }

        _position.collateral = _position.collateral + collateralDelta;
        _position.entryFundingRate = fundingRate;
        _position.size = _position.size + sizeDelta;
        _position.isLong = isLong;
        _position.lastTime = uint32(block.timestamp);

        require(_position.isValid(), "positionBook: invalid position");

        _updatePosition(
            account,
            isLong,
            collateralDelta,
            sizeDelta,
            markPrice,
            true,
            _position
        );

        result.size = _position.size;
        result.collateral = _position.collateral;
    }

    function decreasePosition(
        address account,
        uint256 collateralDelta,
        uint256 sizeDelta,
        int256 fundingRate,
        bool isLong
    ) external onlyController returns (Position.Props memory result) {
        return
            _decreasePosition(
                account,
                collateralDelta,
                sizeDelta,
                fundingRate,
                isLong
            );
    }

    function decreaseCollateralFromCancelInvalidOrder(
        address account,
        uint256 collateralDelta,
        int256 fundingRate,
        bool isLong
    ) external onlyController returns (uint256) {
        Position.Props memory _position = _getPosition(account, isLong);
        if (collateralDelta > _position.collateral) {
            collateralDelta = _position.collateral;
        }

        Position.Props memory _result;
        _result = _decreasePosition(
            account,
            collateralDelta,
            0,
            fundingRate,
            isLong
        );

        return _position.collateral - _result.collateral;
    }

    function liquidatePosition(
        address account,
        uint256 markPrice,
        bool isLong
    ) external onlyController returns (Position.Props memory result) {
        Position.Props memory _position = _getPosition(account, isLong);
        require(_position.isExist(), "positionBook: position does not exist");

        if (markPrice != 0) {
            (bool _hasProfit, uint256 _realisedPnl) = _getPNL(
                _position,
                markPrice
            );
            int256 _pnl = _hasProfit
                ? int256(_realisedPnl)
                : -int256(_realisedPnl);

            result.realisedPnl = _pnl;
        }

        _delPosition(account, _position.collateral, _position.size, isLong);

        result.size = _position.size;
        result.collateral = _position.collateral;
    }

    function _decreasePosition(
        address account,
        uint256 collateralDelta,
        uint256 sizeDelta,
        int256 fundingRate,
        bool isLong
    ) private returns (Position.Props memory result) {
        Position.Props memory _position = _getPosition(account, isLong);

        require(_position.isValid(), "positionBook: invalid position");
        require(
            _position.collateral >= collateralDelta,
            "positionBook: invalid collateral"
        );
        require(_position.size >= sizeDelta, "positionBook: invalid size");

        if (_position.size != sizeDelta) {
            _position.entryFundingRate = fundingRate;
            _position.size = _position.size - sizeDelta;
            _position.collateral = _position.collateral - collateralDelta;

            require(_position.isValid(), "positionBook: invalid position");

            _updatePosition(
                account,
                isLong,
                collateralDelta,
                sizeDelta,
                0,
                false,
                _position
            );

            result.size = _position.size;
            result.collateral = _position.collateral;
        } else {
            _delPosition(account, collateralDelta, sizeDelta, isLong);
        }
    }

    function _getPosition(
        address account,
        bool isLong
    ) private view returns (Position.Props memory) {
        PositionStore _store = isLong ? longStore : shortStore;
        return _store.get(account);
    }

    function _getPositionData(
        address account,
        uint256 markPrice,
        bool isLong
    ) private view returns (Position.Props memory) {
        Position.Props memory _position = _getPosition(account, isLong);

        if (markPrice == 0) {
            return _position;
        }

        if (_position.size != 0) {
            (bool _hasProfit, uint256 _realisedPnl) = _getPNL(
                _position,
                markPrice
            );

            int256 _pnl = _hasProfit
                ? int256(_realisedPnl)
                : -int256(_realisedPnl);
            _position.realisedPnl = _pnl;
        }

        return _position;
    }

    function _getPositionKeys(
        PositionStore store,
        uint256 start,
        uint256 end
    ) private view returns (address[] memory) {
        uint256 _len = store.getPositionCount();
        if (_len == 0) {
            return new address[](0);
        }

        if (end > _len) {
            end = _len;
        }
        return store.getPositionKeys(start, end);
    }

    function _getPNL(
        Position.Props memory position,
        uint256 markPrice
    ) private pure returns (bool, uint256) {
        bool _hasProfit;
        uint256 _realisedPnl;

        (_hasProfit, _realisedPnl) = position.getPNL(markPrice);

        return (_hasProfit, _realisedPnl);
    }

    function _getMarketPNL(
        uint256 markPrice,
        bool isLong
    ) private view returns (int256) {
        Position.Props memory _position = _getGlobalPosition(isLong);

        if (_position.size == 0) {
            return 0;
        }

        (bool _hasProfit, uint256 _pnl) = _getPNL(_position, markPrice);
        return _hasProfit ? int256(_pnl) : -int256(_pnl);
    }

    function _calGlobalPosition(
        uint256 collateralDelta,
        uint256 sizeDelta,
        uint256 markPrice,
        bool isLong,
        bool isOpen
    ) private view returns (Position.Props memory) {
        Position.Props memory _position = _getGlobalPosition(isLong);

        if (isOpen) {
            uint256 _averagePrice = _getGlobalAveragePrice(
                _position,
                sizeDelta,
                markPrice
            );
            require(_averagePrice > 100, "pb:invalid global position");
            _position.averagePrice = _averagePrice;
            _position.size += sizeDelta;
            _position.collateral += collateralDelta;

            return _position;
        }

        _position.size -= sizeDelta;
        _position.collateral -= collateralDelta;

        return _position;
    }

    function _getGlobalAveragePrice(
        Position.Props memory position,
        uint256 sizeDelta,
        uint256 markPrice
    ) private pure returns (uint256) {
        if (position.size == 0) {
            return markPrice;
        }
        if (position.size > 0 && sizeDelta > 0) {
            (bool _hasProfit, uint256 _pnl) = _getPNL(position, markPrice);
            position.averagePrice = position.calAveragePrice(
                sizeDelta,
                markPrice,
                _pnl,
                _hasProfit
            );
        }

        return position.averagePrice;
    }

    function _getGlobalPosition(
        bool isLong
    ) private view returns (Position.Props memory) {
        PositionStore _store = isLong ? longStore : shortStore;
        return _store.getGlobalPosition();
    }

    function _updatePosition(
        address account,
        bool isLong,
        uint256 collateralDelta,
        uint256 sizeDelta,
        uint256 markPrice,
        bool isOpen,
        Position.Props memory position
    ) private {
        Position.Props memory _globalPosition = _calGlobalPosition(
            collateralDelta,
            sizeDelta,
            markPrice,
            isLong,
            isOpen
        );

        PositionStore _store = isLong ? longStore : shortStore;
        _store.set(account, position, _globalPosition);
    }

    function _delPosition(
        address account,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong
    ) private {
        Position.Props memory _globalPosition = _calGlobalPosition(
            collateralDelta,
            sizeDelta,
            0,
            isLong,
            false
        );

        PositionStore _store = isLong ? longStore : shortStore;
        _store.remove(account, _globalPosition);
    }
}
