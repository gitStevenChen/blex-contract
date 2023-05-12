// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ac is AccessControl, Ownable {
    bytes32 internal constant ROLE_CONTROLLER = keccak256("ROLE_CONTROLLER");
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 internal constant ROLE_POS_KEEPER = keccak256("ROLE_POS_KEEPER");
    bytes32 internal constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 internal constant BOSS_ROLE = keccak256("BOSS_ROLE");
    bytes32 internal constant MARKET_MGR_ROLE = keccak256("MARKET_MGR_ROLE");
    bytes32 internal constant GLOBAL_MGR_ROLE = keccak256("GLOBAL_MGR_ROLE");
    bytes32 internal constant VAULT_MGR_ROLE = keccak256("VAULT_MGR_ROLE");
    bytes32 internal constant FEE_DISTRIBUTOR_ROLE =
        keccak256("FEE_DISTRIBUTOR_ROLE");
    bytes32 internal constant FEE_MGR_ROLE = keccak256("FEE_MGR_ROLE");
    bytes32 internal constant PRICE_UPDATE_ROLE =
        keccak256("PRICE_UPDATE_ROLE");

    bool public initialized = false;

    modifier initializeLock() {
        require(false == initialized, "initialized");

        _;
        initialized = true;
    }

    constructor(address _f) Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, _f);

        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, _f);
    }

    function grantAndRevoke(bytes32 role, address account) external {
        grantRole(role, account);
    }

    modifier onlyAdmin() {
        _checkRole(MANAGER_ROLE);
        _;
    }

    modifier onlyPositionKeeper() {
        _checkRole(ROLE_POS_KEEPER);
        _;
    }

    modifier onlyController() {
        _checkRole(ROLE_CONTROLLER);
        _;
    }

    modifier onlyUpdater() {
        require(hasRole(PRICE_UPDATE_ROLE, msg.sender));
        _;
    }
}
