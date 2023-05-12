// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MockOracle {
    uint256 public constant PRICE_PRECISION = 10 ** 30;

    mapping(address => uint256) private prices;

    function setPrice(address token, uint256 price) external {
        require(token != address(0), "invalid token");
        require(price > 0, "invalid price");

        prices[token] = price;
    }

    function getPrice(
        address _token,
        bool _maximise
    ) external view returns (uint256) {
        uint256 _price = prices[_token];
        require(_price > 0, "wrong token or price not set");
        // return _price * PRICE_PRECISION;
        return _price;
    }

    function setPrices(
        address[] memory _tokens,
        uint256[] memory _prices,
        uint256 _timestamp
    ) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 price = _prices[i];

            require(token != address(0), "invalid token");
            require(price > 0, "invalid price");
            prices[token] = price;
        }
    }
}
