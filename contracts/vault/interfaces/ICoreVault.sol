// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

interface ICoreVault is IERC4626 {
    // 设置路由地址
    function setVaultRouter(address vaultRouter) external;
    // 
    function setLpFee(bool isBuy, uint256 fee) external;

    function sellLpFee() external view returns (uint256);

    function buyLpFee() external view returns (uint256);
    // 设置冷却时间
    function setCooldownDuration(uint256 duration) external;
    // 计算交易成本
    function computationalCosts(
        bool isBuy,
        uint256 amount
    ) external view returns (uint256);
    // 验证转出资产
    function verifyOutAssets(
        address to,
        uint256 amount
    ) external view returns (bool);
    // 转出资产
    function transferOutAssets(address to, uint256 amount) external;

    function getLPFee(bool isBuy) external view returns (uint256);
    // 是否冻结
    function setIsFreeze(bool f) external;
    // 初始化
    function initialize(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _vaultRouter,
        address
    ) external;
}
