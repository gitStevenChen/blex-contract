// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {ICoreVault, IERC4626} from "./interfaces/ICoreVault.sol";
import {IVaultRouter} from "./interfaces/IVaultRouter.sol";

import {Precision} from "../utils/TransferHelper.sol";
import {Ac} from "../ac/Ac.sol";

// transferOwnership to timelock contract
contract CoreVault is ERC4626, Ac, ICoreVault {
    using Math for uint256;
    using SafeERC20 for IERC20;

    IVaultRouter public vaultRouter;

    mapping(address => uint256) public lastDepositAt;
    uint256 public cooldownDuration = 15 minutes;
    uint256 public constant FEE_RATE_PRECISION = Precision.FEE_RATE_PRECISION;
    uint256 public buyLpFee = (2 * FEE_RATE_PRECISION) / 100;
    uint256 public sellLpFee = (1 * FEE_RATE_PRECISION) / 100;
    event CoolDownDurationUpdated(uint256 duration);
    event LPFeeUpdated(bool isBuy, uint256 fee);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(IERC20(_asset)) ERC20(_name, _symbol) Ac(msg.sender) {}

    function initialize(address _vaultRouter) public initializeLock {
        vaultRouter = IVaultRouter(_vaultRouter);
        _grantRole(ROLE_CONTROLLER, _vaultRouter);
    }

    function setVaultRouter(address _vaultRouter) external override onlyAdmin {
        vaultRouter = IVaultRouter(_vaultRouter);
        _grantRole(ROLE_CONTROLLER, _vaultRouter);
    }

    function setLpFee(bool isBuy, uint256 fee) public override onlyAdmin {
        isBuy ? buyLpFee = fee : sellLpFee = fee;
        emit LPFeeUpdated(isBuy, fee);
    }

    function setCooldownDuration(uint256 _duration) public override onlyAdmin {
        cooldownDuration = _duration;
        emit CoolDownDurationUpdated(_duration);
    }

    function transferOutAssets(
        address to,
        uint256 amount
    ) external override onlyController {
        SafeERC20.safeTransfer(IERC20(asset()), to, amount);
    }

    function totalAssets()
        public
        view
        override(ERC4626, IERC4626)
        returns (uint256)
    {
        return vaultRouter.getAUM();
    }

    function computationalCosts(
        bool isBuy,
        uint256 amount
    ) public view override returns (uint256) {
        if (isBuy) {
            return (amount * (buyLpFee)) / FEE_RATE_PRECISION;
        } else {
            return (amount * (sellLpFee)) / FEE_RATE_PRECISION;
        }
    }

    function getLPFee(bool isBuy) public view override returns (uint256) {
        return isBuy ? buyLpFee : sellLpFee;
    }

    function _convertToShares(
        uint256 assets,
        Math.Rounding rounding
    ) internal view override returns (uint256 shares) {
        shares = super._convertToShares(assets, rounding);
        bool isBuy = rounding == Math.Rounding.Down;
        if (isBuy) return shares - computationalCosts(isBuy, shares);
        else
            return
                (shares * FEE_RATE_PRECISION) /
                (FEE_RATE_PRECISION - sellLpFee);
    }

    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view override returns (uint256 assets) {
        assets = super._convertToAssets(shares, rounding);
        bool isBuy = rounding == Math.Rounding.Up;
        if (isBuy)
            return
                (assets * FEE_RATE_PRECISION) / (FEE_RATE_PRECISION - buyLpFee);
        else return assets - computationalCosts(isBuy, assets);
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        lastDepositAt[receiver] = block.timestamp;
        uint256 s_assets = super._convertToAssets(shares, Math.Rounding.Up);
        uint256 cost = assets > s_assets
            ? assets - s_assets
            : s_assets - assets;
        vaultRouter.transFeeTofeeVault(receiver, address(asset()), cost, true);
        super._deposit(caller, receiver, assets - cost, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        require(
            block.timestamp > cooldownDuration + lastDepositAt[receiver],
            "can't withdraw within 15min"
        );
        uint256 s_assets = super._convertToAssets(shares, Math.Rounding.Down);
        bool exceeds_assets = s_assets > assets;
        super._withdraw(
            caller,
            address(vaultRouter),
            owner,
            exceeds_assets ? s_assets : assets,
            shares
        );
        uint256 cost = exceeds_assets ? s_assets - assets : assets - s_assets;
        vaultRouter.transFeeTofeeVault(receiver, address(asset()), cost, false);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);
    }

    function verifyOutAssets(
        address /* to */,
        uint256 /* amount */
    ) external pure override returns (bool) {
        return true;
    }
}
