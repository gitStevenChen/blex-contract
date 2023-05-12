// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPositionBook} from "../position/interfaces/IPositionBook.sol";

contract MockMarket {
    address public PositionBook;

    function setPositionBook(address book) external {
        PositionBook = book;
    }

    function indexToken() external view returns (address) {
        return address(this);
    }

    function positionBook() external returns (IPositionBook) {
        return IPositionBook(PositionBook);
    }
}
