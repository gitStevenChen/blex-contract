// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ERC20} from "./ERC20.sol";
import {ERC4626} from "./ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICoreVault, IERC4626} from "./interfaces/ICoreVault.sol";
import {IVaultRouter} from "./interfaces/IVaultRouter.sol";
import "hardhat/console.sol";
import {Precision, TransferHelper} from "../utils/TransferHelper.sol";
import {AcUpgradable} from "../ac/AcUpgradable.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";

contract CoreVault is ERC4626, AcUpgradable, ICoreVault {
    using Math for uint256;
    using SafeERC20 for IERC20;

    IVaultRouter public vaultRouter;
    bool public isFreeze = false;

    IFeeRouter public feeRouter;
    // 存储每个账户上一次存款的时间戳
    mapping(address => uint256) public lastDepositAt;
    // 取款操作的冷却时间
    uint256 public cooldownDuration;
    // 精确表示费率（fee rate）的倍数
    uint256 public constant FEE_RATE_PRECISION = Precision.FEE_RATE_PRECISION;
    // 买入LP（流动性提供者）时的费用
    uint256 public buyLpFee;
    // 卖出LP时的费用
    uint256 public sellLpFee;
    // 当取款操作的冷却时间被更新时，该事件会被触发
    event CoolDownDurationUpdated(uint256 duration);
    // 买入或卖出LP的费用被更新时，该事件会被触发
    event LPFeeUpdated(bool isBuy, uint256 fee);
    // 当用户进行存款操作时，该事件会被触发，记录存款的相关信息
    event DepositAsset(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares,
        uint256 fee
    );
    // 当用户进行取款操作时，该事件会被触发，记录取款的相关信息
    event WithdrawAsset(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares,
        uint256 fee
    );
    // 初始化，修饰器initializer，参数_asset是资金池的代币地址(比如USDC)，AcUpgradable是角色权限管理
    function initialize(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _vaultRouter,
        address _feeRouter
    ) external initializer {
        ERC20._initialize(_name, _symbol);
        ERC4626._initialize(IERC20(_asset));
        AcUpgradable._initialize(msg.sender);

        vaultRouter = IVaultRouter(_vaultRouter);
        // 将一个角色（role）授予指定地址(open的方法)
        _grantRole(ROLE_CONTROLLER, _vaultRouter);
        feeRouter = IFeeRouter(_feeRouter);

        cooldownDuration = 15 minutes;
        sellLpFee = (1 * FEE_RATE_PRECISION) / 100;
    }

    function setVaultRouter(address _vaultRouter) external override onlyAdmin {
        if (address(vaultRouter) != address(0))
            _revokeRole(ROLE_CONTROLLER, address(vaultRouter));
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

    function _transFeeTofeeVault(
        address account,
        address _asset,
        uint256 fee,
        bool isBuy
    ) private {
        if (fee == 0) return;

        uint8 kind = (isBuy ? 5 : 6);
        int256[] memory fees = new int256[](kind + 1);
        IERC20(_asset).approve(address(feeRouter), fee);
        fees[kind] = int256(
            TransferHelper.parseVaultAsset(
                fee,
                IERC20Metadata(_asset).decimals()
            )
        );
        feeRouter.collectFees(account, _asset, fees);
    }

    uint256 constant NUMBER_OF_DEAD_SHARES = 1000;

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        require(false == isFreeze, "vault freeze");
        lastDepositAt[receiver] = block.timestamp;
        uint256 s_assets = super._convertToAssets(shares, Math.Rounding.Up);
        uint256 cost = assets > s_assets
            ? assets - s_assets
            : s_assets - assets;
        uint256 _assets = assets > s_assets ? assets : s_assets;

        if (totalSupply() == 0) {
            _mint(address(0), NUMBER_OF_DEAD_SHARES);
            shares -= NUMBER_OF_DEAD_SHARES;
        }
        super._deposit(caller, receiver, _assets, shares);
        _transFeeTofeeVault(receiver, address(asset()), cost, true);

        emit DepositAsset(caller, receiver, assets, shares, cost);
    }

    function _withdraw(
        address caller,
        address receiver,
        address _owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        require(false == isFreeze, "vault freeze");
        require(
            block.timestamp > cooldownDuration + lastDepositAt[_owner],
            "can't withdraw within 15min"
        );
        uint256 s_assets = super._convertToAssets(shares, Math.Rounding.Down);
        bool exceeds_assets = s_assets > assets;

        uint256 _assets = exceeds_assets ? assets : s_assets;

        super._withdraw(caller, receiver, _owner, _assets, shares);

        uint256 cost = exceeds_assets ? s_assets - assets : assets - s_assets;

        _transFeeTofeeVault(_owner, address(asset()), cost, false);

        emit WithdrawAsset(caller, receiver, _owner, assets, shares, cost);
    }

    event LogIsFreeze(bool isFreeze);

    function setIsFreeze(bool f) external onlyFreezer {
        isFreeze = f;
        emit LogIsFreeze(f);
    }

    function verifyOutAssets(
        address to,
        uint256 amount
    ) external view override returns (bool) {
        return true;
    }

    uint256[50] private ______gap;
}
