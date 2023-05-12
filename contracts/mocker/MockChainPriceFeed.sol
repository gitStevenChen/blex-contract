// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oracle/interfaces/IFastPriceFeed.sol";

contract ChainPriceFeedMock {
    address public fastPrice;

    function setFastPrice (address feed) external {
        fastPrice = feed;
    }

    function getPrice(
        address _token,
        bool _maximise
    ) public view returns (uint256) {
        return IFastPriceFeed(fastPrice).prices(_token);
    }
}
