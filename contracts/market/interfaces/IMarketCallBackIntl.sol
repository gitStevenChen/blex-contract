// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../MarketDataTypes.sol";
import "../../position/PositionStruct.sol";

interface MarketPositionCallBackIntl {
    //=====================================
    //      UPDATE POSITION
    //=====================================
    struct UpdatePositionEvent {
        MarketDataTypes.UpdatePositionInputs inputs;
        Position.Props position;
        int256[] fees;
        address collateralToken;
        address indexToken;
        int256 collateralDeltaAfter;
    }

    function updatePositionCallback(UpdatePositionEvent memory _event) external;
}

interface MarketOrderCallBackIntl {
    //=====================================
    //      UPDATE ORDER
    //=====================================
    function updateOrderCallback(
        MarketDataTypes.UpdateOrderInputs memory _event
    ) external;

    //=====================================
    //      DEL ORDER
    //=====================================
    struct DeleteOrderEvent {
        Order.Props order;
        MarketDataTypes.UpdatePositionInputs inputs;
        uint8 reason;
        int256 dPNL;
    }

    function deleteOrderCallback(DeleteOrderEvent memory e) external;
}
