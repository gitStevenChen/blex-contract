//SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./ICoreVault.sol";
import {IFeeRouter} from "../../fee/interfaces/IFeeRouter.sol";

interface IVaultRouter {
    // 获取总计使用的资金数量
    function totalFundsUsed() external view returns (uint256);
    // 获取关联的费用路由器（Fee Router）的地址
    function feeRouter() external view returns (IFeeRouter);
    // 初始化方法，用于设置Vault Router合约所需的核心Vault（资金池）和费用路由器的地址
    function initialize(address _coreVault, address _feeRouter) external;
    // 设置市场（Market），与特定的核心Vault关联一个市场
    function setMarket(address market, ICoreVault vault) external;
    // 从Vault中借款
    function borrowFromVault(uint256 amount) external;
    // 还款到Vault
    function repayToVault(uint256 amount) external;
    // 将资产转移至Vault
    function transferToVault(address account, uint256 amount) external;
    // 从Vault中转移资产
    function transferFromVault(address to, uint256 amount) external;
    // 获取Vault Router合约中管理资产总值
    function getAUM() external view returns (uint256);
    // 获取全局盈亏
    function getGlobalPnl() external view returns (int256);
    // 获取特定核心Vault的LP（流动性提供者）价格
    function getLPPrice(address coreVault) external view returns (uint256);
    // 获取Vault Router合约中存储的USD余额
    function getUSDBalance() external view returns (uint256);
    // 获取价格的小数位数
    function priceDecimals() external view returns (uint256);
    // 获取购买LP时的费用
    function buyLpFee(ICoreVault vault) external view returns (uint256);
    // 获取出售LP时的费用
    function sellLpFee(ICoreVault vault) external view returns (uint256);
    // 出售Vault份额，返回实际出售的资产数量
    function sell(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minAssetsOut
    ) external returns (uint256 assetsOut);
    // 购买Vault份额，返回实际购买的份额数量
    function buy(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);
    // 将手续费转移到费用Vault
    function transFeeTofeeVault(
        address account,
        address asset,
        uint256 fee, // assets decimals
        bool isBuy
    ) external;
}
