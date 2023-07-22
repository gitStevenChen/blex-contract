//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./ICoreVault.sol";

// 用于与奖励管理器合约进行交互，管理Vault（资金池）的奖励相关功能
interface IVaultReward {
    // 更新奖励的方法
    function updateRewards() external;
    // 初始化方法，用于设置奖励管理器合约所需的核心Vault（资金池）、Vault路由器和费用路由器的地址
    function initialize(
        address _coreVault,
        address _vaultRouter,
        address _feeRouter
    ) external;
    // 购买Vault份额。用户可以通过调用这个函数来购买Vault份额，返回实际购买的份额数量
    function buy(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256); // move
    // 出售Vault份额。用户可以通过调用这个函数来出售Vault份额，返回实际出售的资产数量
    function sell(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minAssetsOut
    ) external returns (uint256); // move
    // 领取LP奖励
    function calimLPReward() external;
    // 获取当前年化收益率
    function getAPR() external returns (uint256);
    // 获取奖励管理器合约中存储的USD余额
    function getUSDBalance() external view returns (uint256); // move
    // 获取Vault的管理资产总值
    function getAUM() external returns (uint256);
    // 获取当前LP奖励的数量
    function getLPReward() external returns (uint256);
    // 获取尚未领取的奖励数量
    function pendingRewards() external returns (uint256);
    // 获取LP（流动性提供者）的价格
    function getLPPrice() external returns (uint256); // move
    // 获取价格的小数位数
    function priceDecimals() external returns (uint256);
    // 获取购买LP时的费用
    function buyLpFee(ICoreVault vault) external view returns (uint256);
    // 获取出售LP时的费用的方法
    function sellLpFee(ICoreVault vault) external view returns (uint256);
}
