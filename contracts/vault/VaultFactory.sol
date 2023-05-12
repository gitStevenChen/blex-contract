// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
import {Ac} from "../ac/Ac.sol";
import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";
import {ICoreVault} from "./interfaces/ICoreVault.sol";
import {IVaultRouter} from "./interfaces/IVaultRouter.sol";
import {IVaultReward} from "./interfaces/IVaultReward.sol";

contract VaultFactory is Ac {
    address public rewardDistributor;
    address public coreVault;
    address public vaultRouter;
    address public vaultReward;
    address public assets;

    constructor() Ac(address(msg.sender)) {}

    function initialize(
        address _asset,
        address _feeRouter,
        address _rewardDistributor,
        address _coreVault,
        address _vaultRouter,
        address _vaultReward
    ) external onlyAdmin {
        assets = _asset;
        rewardDistributor = _rewardDistributor;
        coreVault = _coreVault;
        vaultRouter = _vaultRouter;
        vaultReward = _vaultReward;

        ICoreVault(coreVault).initialize(vaultRouter);
        IVaultRouter(vaultRouter).initialize(address(coreVault), _feeRouter);
        IVaultReward(vaultReward).initialize(
            coreVault,
            vaultRouter,
            _feeRouter
        );
        IRewardDistributor(rewardDistributor).initialize(assets, vaultReward);
        Ac(coreVault).grantRole(ROLE_CONTROLLER, vaultReward);
    }

    function setMarket(address market) external onlyAdmin {
        IVaultRouter(vaultRouter).setMarket(market, ICoreVault(coreVault));
    }
}
