// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AcUpgradable.sol";

contract Ac is AcUpgradable {
    constructor(address _f) Ownable() {
        AcUpgradable._initialize(_f);
    }
}
