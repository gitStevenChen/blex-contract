//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IMarket} from "../market/interfaces/IMarket.sol";
import {ICoreVault} from "./interfaces/ICoreVault.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {AcUpgradable} from "../ac/AcUpgradable.sol";
import {TransferHelper} from "../utils/TransferHelper.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VaultRouter is AcUpgradable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IFeeRouter public feeRouter;
    ICoreVault public coreVault;

    EnumerableSet.AddressSet private markets;
    EnumerableSet.AddressSet private vaults;
    bool public isFreeze = false;

    uint256 public totalFundsUsed;
    mapping(address => uint256) public fundsUsed;
    mapping(address => ICoreVault) public marketVaults;
    mapping(ICoreVault => address) public vaultMarkets;

    event LogIsFreeze(bool isFreeze);

    modifier onlyMarket() {
        require(markets.contains(msg.sender), "invalid market");
        _;
    }

    function setIsFreeze(bool f) external onlyFreezer {
        isFreeze = f;
        coreVault.setIsFreeze(f);
        emit LogIsFreeze(f);
    }

    function initialize(
        address _coreVault,
        address _feeRouter
    ) public initializer {
        AcUpgradable._initialize(msg.sender);
        coreVault = ICoreVault(_coreVault);
        feeRouter = IFeeRouter(_feeRouter);
    }

    event MarketSetted(address market, address vault);

    function setMarket(
        address market,
        ICoreVault vault
    ) external onlyRole(VAULT_MGR_ROLE) {
        markets.add(market);
        marketVaults[market] = vault;
        vaultMarkets[vault] = market;
        vaults.add(address(vault));
        _grantRole(ROLE_CONTROLLER, market);
        emit MarketSetted(market, address(vault));
    }

    event MarketRemoved(address market, address vault);

    function removeMarket(address market) external onlyRole(VAULT_MGR_ROLE) {
        markets.remove(market);
        address vlt = address(marketVaults[market]);
        vaults.remove(vlt);
        delete (vaultMarkets[marketVaults[market]]);
        delete (marketVaults[market]);
        _revokeRole(ROLE_CONTROLLER, market);
        emit MarketRemoved(market, vlt);
    }

    /**
     * @dev Transfers a specified amount of an ERC20 asset from `account` to the corresponding `ICoreVault` associated with the calling `msg.sender` market contract.
     * @param account The address of the account from which the tokens will be transferred.
     * @param amount The amount of tokens to be transferred to the vault.
     * @notice This function can only be called by a contract with the MARKET_ROLE.
     */
    function transferToVault(
        address account,
        uint256 amount
    ) external onlyController {
        require(false == isFreeze, "freeze");
        ICoreVault vault = marketVaults[msg.sender];
        SafeERC20.safeTransferFrom(
            IERC20(vault.asset()),
            account,
            address(vault),
            amount
        );
    }

    /**
     * @dev Transfers a specified amount of assets from the vault of the calling market to a specified address.
     * Only a market role can call this function.
     * @param to The address to transfer the assets to.
     * @param amount The amount of assets to transfer.
     */
    function transferFromVault(
        address to,
        uint256 amount
    ) external onlyController {
        require(false == isFreeze, "freeze");
        ICoreVault vault = marketVaults[msg.sender];
        if (vault.verifyOutAssets(to, amount)) {
            vault.transferOutAssets(to, amount);
        }
    }

    /**
     * @dev Function to borrow tokens from the Vault of a market.
     * @param amount The amount of tokens to borrow.
     * @notice This function can only be called by a market contract that has been added to the 'markets' set.
     *         The function updates the funds used in the market by the borrowed amount, using the 'updateFundsUsed' internal function.
     *         The borrowed tokens will be transferred to the caller's address.
     */
    function borrowFromVault(uint256 amount) external onlyMarket {
        require(false == isFreeze, "freeze");

        require(markets.contains(msg.sender), "invalid market");
        updateFundsUsed(msg.sender, amount, true);
    }

    /**
     * @dev This function is used to repay a specified amount of borrowed funds to the Vault contract by the market contract that calls it.
     * @param amount The amount of borrowed funds to be repaid.
     * The function checks if the market contract calling the function is a valid market. If the market is valid, it calls the "updateFundsUsed" function to update the amount of funds used by the market. The "amount" parameter is used to specify the amount of funds being repaid. Once the update is completed, the borrowed funds are returned to the Vault contract, and the function completes execution.
     */
    function repayToVault(uint256 amount) external onlyMarket {
        require(false == isFreeze, "freeze");
        updateFundsUsed(msg.sender, amount, false);
    }

    event FundsUsedUpdated(
        address indexed market,
        uint256 amount,
        uint256 totalFundsUsed
    );

    function updateFundsUsed(
        address market,
        uint256 amount,
        bool isBorrow
    ) private {
        if (isBorrow) {
            uint256 pendingFundsUsed = totalFundsUsed + amount;
            uint256 aum = getAUM();

            require(aum > 0, "inlvalid aum");
            require(pendingFundsUsed < aum, "not enough funds to borrow");

            fundsUsed[market] += amount;
            totalFundsUsed = pendingFundsUsed;
        } else {
            fundsUsed[market] -= amount;
            totalFundsUsed -= amount;
        }
        emit FundsUsedUpdated(market, fundsUsed[market], totalFundsUsed);
    }

    /**
     * @dev This function is used to calculate the total USD balance of all the Vaults in the system.
     * @return totalAssets The total USD balance of all the Vaults in the system.
     *
     * The function retrieves the addresses of all the Vaults in the system and calculates the total USD balance of all the Vaults. This is done by iterating over all the Vault addresses and calling the "balanceOf" function of the asset token associated with each Vault to retrieve the USD balance. The retrieved balances are then summed up to give the "totalAssets" of all the Vaults in the system. This value is returned as the output of the function.
     */
    function getUSDBalance() public view returns (uint256) {
        address[] memory vaultAddrs = vaults.values();
        uint256 totalAssets;
        for (uint256 i = 0; i < vaultAddrs.length; i++) {
            address vault = vaultAddrs[i];
            totalAssets += IERC20(ICoreVault(vault).asset()).balanceOf(vault);
        }

        return totalAssets;
    }

    /**
     * @dev This function calculates the global profit and loss (PNL) across all markets.
     * @return pnl The total global PNL as an int256 value.
     */
    function getGlobalPnl() public view returns (int256) {
        address[] memory _markets = markets.values();
        int256 pnl = 0;
        for (uint256 i = 0; i < _markets.length; i++) {
            pnl = pnl + IMarket(_markets[i]).getPNL();
        }
        return pnl;
    }

    /**
     * @dev This function calculates the assets under management (AUM) of the contract.
     * @return aum The AUM value as a uint256.
     */
    function getAUM() public view returns (uint256) {
        int256 unbalancedPnl = getGlobalPnl();
        uint256 usdBalance = getUSDBalance();
        uint256 aum;
        if (unbalancedPnl > 0) {
            aum = usdBalance + uint256(unbalancedPnl);
        } else {
            require(
                usdBalance >= uint256(-unbalancedPnl),
                "invalid usd balance"
            );
            aum = usdBalance - uint256(-unbalancedPnl);
        }
        return aum;
    }

    /**
     * @dev Returns the number of decimal places for the price of the underlying asset in the CoreVault contract.
     * @return The number of decimal places for the price of the underlying asset.
     */
    function priceDecimals() public pure returns (uint256) {
        return 8;
    }

    /**
     * @dev This function returns the LP fee charged by the specified vault when selling LP tokens.
     * @param vault The address of the vault for which to retrieve the LP fee.
     * @return lpFee The LP fee charged by the specified vault as a uint256 value.
     */
    function sellLpFee(ICoreVault vault) external view returns (uint256) {
        return vault.getLPFee(false);
    }

    /**
     * @dev This function is used to get the buy Liquidity Provider (LP) fee percentage of a specified Vault.
     * @param vault The address of the Vault for which the buy LP fee is to be retrieved.
     * @return The buy LP fee percentage of the specified Vault.
     *
     * The function calls the "getLPFee" function of the specified Vault with the boolean argument "true" to retrieve the buy LP fee percentage. The retrieved buy LP fee percentage is returned as the output of the function.
     */
    function buyLpFee(ICoreVault vault) external view returns (uint256) {
        return vault.getLPFee(true);
    }

    uint256[50] private ______gap;
}
