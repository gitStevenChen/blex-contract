//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IRewardDistributor {
    function initialize(address _rewardToken, address _rewardTracker) external;

    function pendingRewards() external view returns (uint256);

    function distribute() external returns (uint256);

    function tokensPerInterval() external view returns (uint256);
}
