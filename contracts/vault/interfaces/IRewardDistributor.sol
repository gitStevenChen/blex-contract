//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// 奖励分配器
interface IRewardDistributor {
    // 初始化，两个参数，分别是奖励代币的地址和奖励跟踪器（Tracker）的地址
    function initialize(address _rewardToken, address _rewardTracker) external;
    // 查询当前奖励分配器尚未分配的奖励数量
    function pendingRewards() external view returns (uint256);
    // 执行奖励分配操作，将奖励分配给指定的账户，并返回实际分配的奖励数量
    function distribute() external returns (uint256);
    // 查询每个分配周期（Interval）中将要分配的奖励数量
    function tokensPerInterval() external view returns (uint256);
}
