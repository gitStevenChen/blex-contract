// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../PositionStruct.sol";

interface IPositionStore {
    function positionBook() external view returns (address);

    function isLong() external view returns (bool);

    function get(address account) external view returns (Position.Props memory);

    function globalSize() external view returns (uint256);

    function getGlobalPosition() external view returns (Position.Props memory);

    function contains(address account) external view returns (bool);

    function getPositionCount() external view returns (uint256);

    function getPositionKeys(
        uint256 start,
        uint256 end
    ) external view returns (address[] memory);

    function setPositionBook(address positionBook) external;

    function set(
        address account,
        Position.Props calldata position,
        Position.Props calldata globalPosition
    ) external;

    function remove(
        address account,
        Position.Props calldata globalPosition
    ) external;
}
