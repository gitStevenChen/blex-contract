// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../ac/Ac.sol";

import {IFundFee} from "./interfaces/IFundFee.sol";
import {IFeeVault} from "./interfaces/IFeeVault.sol";
import {MarketDataTypes} from "../market/MarketDataTypes.sol";
import {Position} from "../position/PositionStruct.sol";
import {TransferHelper} from "./../utils/TransferHelper.sol";

import "./interfaces/IFeeRouter.sol";
import {Precision} from "../utils/TransferHelper.sol";

contract FeeRouter is Ac, IFeeRouter {
    using SafeERC20 for IERC20;

    address public feeVault;
    address public fundFee;

    uint256 public constant FEE_RATE_PRECISION = Precision.FEE_RATE_PRECISION;

    // market's feeRate and fee
    mapping(address => mapping(uint8 => uint256)) public feeAndRates;

    event UpdateFee(
        address indexed account,
        address indexed market,
        int256[] fees
    );
    event UpdateFeeAndRates(
        address indexed market,
        uint8 kind,
        uint256 feeOrRate
    );

    constructor(address factory) Ac(factory) {
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    function initialize(
        address vault,
        address fundingFee
    ) external initializeLock {
        require(vault != address(0), "invalid fee vault");
        require(fundingFee != address(0), "invalid fundFee");

        feeVault = vault;
        fundFee = fundingFee;
    }

    function setFeeAndRates(
        address market,
        uint256[] memory rates
    ) external onlyRole(MARKET_MGR_ROLE) {
        require(rates.length > 0, "invalid params");

        for (uint8 i = 0; i < rates.length; i++) {
            if (rates[i] == 0) {
                continue;
            }

            feeAndRates[market][i] = rates[i];
            emit UpdateFeeAndRates(market, i, rates[i]);
        }
    }

    function getGlobalFees() external view returns (int256 total) {
        return IFeeVault(feeVault).getGlobalFees();
    }

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(WITHDRAW_ROLE) {
        IFeeVault(feeVault).withdraw(token, to, amount);
    }

    function updateCumulativeFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize
    ) external onlyController {
        IFundFee(fundFee).updateCumulativeFundingRate(
            market,
            longSize,
            shortSize
        );
    }

    function collectFees(
        address account,
        address token,
        int256[] memory fees
    ) external onlyController {
        if (fees.length == 0) return;

        int256 _fees;
        for (uint256 i = 0; i < fees.length; i++) {
            _fees += fees[i];
        }
        if (_fees == 0) {
            return;
        }

        uint256 _amount = TransferHelper.formatCollateral(
            uint256(_fees),
            IERC20Metadata(token).decimals()
        );
        IERC20(token).safeTransferFrom(msg.sender, feeVault, _amount);
        IFeeVault(feeVault).increaseFees(msg.sender, account, fees);

        emit UpdateFee(account, msg.sender, fees);
    }

    function getExecFee(address market) external view returns (uint256) {
        return feeAndRates[market][uint8(FeeType.ExecFee)];
    }

    function getAccountFees(address account) external view returns (uint256) {
        uint256 _fees = uint256(IFeeVault(feeVault).accountFees(account));
        uint256 _buyFee = uint256(
            IFeeVault(feeVault).accountKindFees(
                account,
                uint8(FeeType.BuyLpFee)
            )
        );
        uint256 _sellFee = uint256(
            IFeeVault(feeVault).accountKindFees(
                account,
                uint8(FeeType.SellLpFee)
            )
        );

        return (_fees - _buyFee - _sellFee);
    }

    function getFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize,
        bool isLong
    ) external view returns (int256) {
        return
            IFundFee(fundFee).getFundingRate(
                market,
                longSize,
                shortSize,
                isLong
            );
    }

    function cumulativeFundingRates(
        address market,
        bool isLong
    ) external view returns (int256) {
        return IFeeVault(feeVault).cumulativeFundingRates(market, isLong);
    }

    function getOrderFees(
        MarketDataTypes.UpdateOrderInputs memory params
    ) external view returns (int256 fees) {
        uint8 _kind;

        if (params.isOpen) {
            _kind = uint8(FeeType.OpenFee);
        } else {
            _kind = uint8(FeeType.CloseFee);
        }

        uint256 _tradeFee = _getFee(params._market, params._order.size, _kind);
        uint256 _execFee = feeAndRates[params._market][uint8(FeeType.ExecFee)];
        return int256(_tradeFee + _execFee);
    }

    function getFees(
        MarketDataTypes.UpdatePositionInputs memory params,
        Position.Props memory position
    ) external view returns (int256[] memory fees) {
        fees = new int256[](uint8(FeeType.Counter));
        address _market = params._market;

        int256 _fundFee = _getFundingFee(
            _market,
            params._isLong,
            position.size,
            position.entryFundingRate
        );
        fees[uint8(FeeType.FundFee)] = _fundFee;

        if (params._sizeDelta == 0 && params.collateralDelta != 0) {
            return fees;
        }

        // open position
        if (params.isOpen) {
            fees[uint8(FeeType.OpenFee)] = int256(
                _getFee(_market, params._sizeDelta, uint8(FeeType.OpenFee))
            );
        } else {
            // close position
            fees[uint8(FeeType.CloseFee)] = int256(
                _getFee(_market, params._sizeDelta, uint8(FeeType.CloseFee))
            );

            // liquidate position
            if (params.liqState == 1) {
                uint256 _fee = feeAndRates[_market][uint8(FeeType.LiqFee)];
                fees[uint8(FeeType.LiqFee)] = int256(_fee);
            }
        }
        if (params.execNum > 0) {
            // exec fee
            uint256 _fee = feeAndRates[_market][uint8(FeeType.ExecFee)];
            _fee = _fee * params.execNum;

            fees[uint8(FeeType.ExecFee)] = int256(_fee);
        }
        return fees;
    }

    function _getFundingFee(
        address market,
        bool isLong,
        uint256 sizeDelta,
        int256 entryFundingRate
    ) private view returns (int256) {
        if (sizeDelta == 0) {
            return 0;
        }

        return
            IFundFee(fundFee).getFundingFee(
                market,
                sizeDelta,
                entryFundingRate,
                isLong
            );
    }

    function _getFee(
        address market,
        uint256 sizeDelta,
        uint8 kind
    ) private view returns (uint256) {
        if (sizeDelta == 0) {
            return 0;
        }

        uint256 _point = feeAndRates[market][kind];
        if (_point == 0) {
            _point = 100000;
        }

        uint256 _size = (sizeDelta * (FEE_RATE_PRECISION - _point)) /
            FEE_RATE_PRECISION;
        return sizeDelta - _size;
    }
}
