// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVaultRouter} from "./interfaces/IVaultRouter.sol";
import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ICoreVault, IERC4626} from "./interfaces/ICoreVault.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ac} from "../ac/Ac.sol";

contract VaultReward is Ac, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeCast for int256;
    using SafeERC20 for IERC20;
    uint256 public constant PRECISION = 1e30;

    IFeeRouter public feeRouter;
    ICoreVault public coreVault;
    //======================
    IVaultRouter public vaultRouter;
    uint256 public cumulativeRewardPerToken;
    address public distributor;

    mapping(address => uint256) public previousCumulatedRewardPerToken;
    mapping(address => uint256) public lpEarnedRewards;
    mapping(address => uint256) public claimableReward;
    mapping(address => uint256) public averageStakedAmounts;

    constructor() Ac(msg.sender) {}

    function initialize(
        address _coreVault,
        address _vaultRouter,
        address _feeRouter,
        address _distributor
    ) public /*onlyRole(DEFAULT_ADMIN_ROLE)*/ initializeLock {
        vaultRouter = IVaultRouter(_vaultRouter);
        coreVault = ICoreVault(_coreVault);
        feeRouter = IFeeRouter(_feeRouter);
        distributor = _distributor;
    }

    /**
     * @dev This function is used to buy shares in a vault using an ERC20 asset as payment.
     * @param vault The address of the vault.
     * @param to The address where the purchased shares will be sent.
     * @param amount The amount of ERC20 tokens to use for purchasing the shares.
     * @param minSharesOut The minimum number of shares that the buyer expects to receive for their payment.
     * @return sharesOut The actual number of shares purchased by the buyer.
     */
    function buy(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) public returns (uint256 sharesOut) {
        SafeERC20.safeTransferFrom(
            IERC20(vault.asset()),
            msg.sender,
            address(this),
            amount
        );
        IERC20(vault.asset()).approve(address(vaultRouter), amount);
        _updateRewards(msg.sender);
        sharesOut = vaultRouter.buy(vault, to, amount, minSharesOut);
    }

    /**
     * @dev This function sells a specified amount of assets in a given vault on behalf of the caller using the `vaultRouter` contract.
     * The `to` address receives the resulting shares of the sale.
     * @param vault The address of the vault to sell assets from.
     * @param to The address that receives the resulting shares of the sale.
     * @param amount The amount of assets to sell.
     * @param minAssetsOut The minimum amount of assets the caller expects to receive from the sale.
     * @return assetOut The resulting number of shares received by the `to` address.
     */
    function sell(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minAssetsOut
    ) public returns (uint256 assetOut) {
        _updateRewards(msg.sender);
        IERC20(vault).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(vault).approve(address(vaultRouter), amount);
        assetOut = vaultRouter.sell(vault, to, amount, minAssetsOut);
    }

    event Harvest(address account, uint256 amount);

    /**
     * @dev This function allows an LP (liquidity provider) to claim their rewards in the current market.
     * The function first checks that the LP has a non-zero balance in the CoreVault contract.
     * If the LP has a non-zero balance, the function calls the `pendingRewards` function to calculate the amount of
     * rewards the LP is entitled to. The LP's earned rewards are then stored in the `lpEarnedRewards` mapping.
     * Finally, the `transferFromVault` function of the `vaultRouter` contract is called to transfer the rewards
     * from the market's vault to the LP's account.
     */
    function claimLPReward() public nonReentrant {
        require(coreVault.balanceOf(msg.sender) > 0, "youn't LP");
        address _account = msg.sender;
        _updateRewards(_account);
        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;
        IERC20(rewardToken()).safeTransfer(msg.sender, tokenAmount);
        emit Harvest(msg.sender, tokenAmount);
    }

    /**
     * @dev This function is used to update rewards.
     * @notice function can only be called without reentry.
     */
    function updateRewards() external nonReentrant {
        _updateRewards(address(0));
    }

    event LogUpdatePool(uint256 supply, uint256 cumulativeRewardPerToken);

    /**
     * @dev This function is used to update rewards.
     * @notice function can only be called without reentry.
     * @param _account needs to update the account address for rewards. If it is 0, the rewards for all accounts will be updated.
     */
    function _updateRewards(address _account) private {
        uint256 blockReward = IRewardDistributor(distributor).distribute();
        uint256 supply = coreVault.totalSupply();
        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;

        if (supply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken =
                _cumulativeRewardPerToken +
                (blockReward * PRECISION) /
                supply;

            cumulativeRewardPerToken = _cumulativeRewardPerToken;

            emit LogUpdatePool(supply, cumulativeRewardPerToken);
        }

        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 stakedAmount = stakedAmounts(_account);
            uint256 accountReward = (stakedAmount *
                (_cumulativeRewardPerToken -
                    previousCumulatedRewardPerToken[_account])) / PRECISION;

            uint256 _claimableReward = claimableReward[_account] +
                accountReward;

            claimableReward[_account] = _claimableReward;
            previousCumulatedRewardPerToken[
                _account
            ] = _cumulativeRewardPerToken;

            if (_claimableReward > 0 && stakedAmounts(_account) > 0) {
                uint256 nextCumulativeReward = lpEarnedRewards[_account] +
                    accountReward;

                averageStakedAmounts[_account] = averageStakedAmounts[_account]
                    .mul(lpEarnedRewards[_account])
                    .div(nextCumulativeReward)
                    .add(
                        stakedAmount.mul(accountReward).div(
                            nextCumulativeReward
                        )
                    );
                lpEarnedRewards[_account] = nextCumulativeReward;
            }
        }
    }

    /**
     * @dev This function allows an LP (liquidity provider) to view the amount of rewards they have earned in the current market.
     * The function uses the `msg.sender` parameter to look up the earned rewards for the calling account in the `lpEarnedRewards` mapping.
     * The function returns the amount of rewards earned by the calling account as a `uint256`.
     * @return The amount of rewards earned by the calling account as a `uint256`.
     */
    function getLPReward() public view returns (uint256) {
        return lpEarnedRewards[msg.sender];
    }

    /**
     * @dev This function allows anyone to retrieve the current price of LP tokens in the current market.
     * The function calls the `getLPPrice` function of the `vaultRouter` contract, passing in the address of the `coreVault` contract.
     * The `getLPPrice` function returns the current price of LP tokens in the market, which is then returned by this function as a `uint256`.
     * @return The current price of LP tokens in the market as a `uint256`.
     */
    function getLPPrice() public view returns (uint256) {
        uint256 assets = coreVault.totalAssets();
        uint256 supply = coreVault.totalSupply();
        if (assets == 0 || supply == 0) return 1 * 10 ** priceDecimals();
        return (assets * 10 ** priceDecimals()) / supply;
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return coreVault.previewDeposit(assets);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) external view returns (uint256) {
        return coreVault.previewMint(shares);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return coreVault.previewWithdraw(assets);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) external view returns (uint256) {
        return coreVault.previewRedeem(shares);
    }

    /**
     * @dev This function retrieves the USD balance of the contract calling the function, by calling the getUSDBalance function of the vaultRouter contract.
     * It does not take any parameters.
     * @return balance The USD balance of the contract calling the function.
     */
    function getUSDBalance() public view returns (uint256) {
        return vaultRouter.getUSDBalance();
    }

    /**
     * @dev This function allows anyone to retrieve the current assets under management (AUM) of the market.
     * The function calls the `getAUM` function of the `vaultRouter` contract, which returns the current AUM of the market as a `uint256`.
     * The AUM represents the total value of assets held in the market, including both the LP tokens and any other tokens held by the market.
     * @return The current AUM of the market as a `uint256`.
     */
    function getAUM() public view returns (uint256) {
        return vaultRouter.getAUM();
    }

    /**
     * @dev This function retrieves the number of decimal places used for price values by calling the priceDecimals function of the vaultRouter contract.
     * It does not take any parameters.
     * @return decimals The number of decimal places used for price values.
     */
    function priceDecimals() public view returns (uint256) {
        return vaultRouter.priceDecimals();
    }

    /**
     * @dev This function retrieves the sell LP fee of a CoreVault contract, by calling the sellLpFee function of the specified CoreVault contract passed as a parameter.
     * @param vault The CoreVault contract from which the sell LP fee is retrieved.
     * @return fee The sell LP fee of the specified CoreVault contract.
     */
    function sellLpFee(ICoreVault vault) public view returns (uint256) {
        return vault.sellLpFee();
    }

    /**
     * @dev This function is part of an interface and is used to retrieve the fee required to buy LP tokens in a market.
     * The function takes in a `CoreVault` parameter representing the CoreVault contract of the market being queried.
     * The function calls the `buyLpFee` function of the `vault` parameter, which returns the fee required to buy LP tokens in the market as a `uint256`.
     * @param vault The `CoreVault` contract of the market being queried.
     * @return The fee required to buy LP tokens in the market as a `uint256`.
     */
    function buyLpFee(ICoreVault vault) public view returns (uint256) {
        return vault.buyLpFee();
    }

    /**
     * @dev This function is used to retrieve the Annual Percentage Rate (APR) for a market.
     * The function calculates the APR by multiplying the tokens distributed per interval by the number of intervals in a year (365), the number of hours in a day (24), and the number of seconds in an hour (3600).
     * The result is then divided by the current LP token price, which is retrieved by calling the `getLPPrice` function.
     * @return The APR for the market as a `uint256`.
     */
    function getAPR() external view returns (uint256) {
        return
            ((IRewardDistributor(distributor).tokensPerInterval() *
                365 *
                24 *
                3600) * (10 ** priceDecimals())) / getAUM();
    }

    /**
     * @dev This function is used to retrieve the number of reward tokens distributed per interval in a market.
     * The function calls the `tokensPerInterval` function of the `IRewardDistributor` contract, which returns the number of reward tokens distributed per interval as a `uint256`.
     * @return The number of reward tokens distributed per interval in the market as a `uint256`.
     */
    function tokensPerInterval() external view returns (uint256) {
        return IRewardDistributor(distributor).tokensPerInterval();
    }

    function rewardToken() public view returns (address) {
        return coreVault.asset();
    }

    function pendingRewards() external view returns (uint256) {
        return claimable(msg.sender);
    }

    /**
     * @dev This function is used to retrieve the amount of rewards claimable by a user in a market.
     * The function calculates the amount of claimable rewards by first retrieving the user's staked amount in the market from the `stakedAmounts` mapping.
     * If the user has no stake, the function returns the previously claimed reward amount stored in the `claimableReward` mapping.
     * Otherwise, the function retrieves the total supply of LP tokens in the market from the `coreVault` contract and the total pending rewards from the `IRewardDistributor` contract.
     * The pending rewards are then multiplied by the `PRECISION` constant and added to the `cumulativeRewardPerToken` variable to calculate the next cumulative reward per token value.
     * The difference between the new cumulative reward per token value and the previous one stored in the `previousCumulatedRewardPerToken` mapping for the user is multiplied by the user's staked amount and divided by the `PRECISION` constant to calculate the claimable reward amount.
     * Finally, the function returns the sum of the user's previously claimed reward amount and the newly calculated claimable reward amount.
     * @param _account The user's account address.
     * @return The amount of rewards claimable by the user in the market as a `uint256`.
     */
    function claimable(address _account) public view returns (uint256) {
        uint256 stakedAmount = stakedAmounts(_account);
        if (stakedAmount == 0) {
            return claimableReward[_account];
        }
        uint256 supply = coreVault.totalSupply();
        uint256 _pendingRewards = IRewardDistributor(distributor)
            .pendingRewards()
            .mul(PRECISION);
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken.add(
            _pendingRewards.div(supply)
        );
        return
            claimableReward[_account].add(
                stakedAmount
                    .mul(
                        nextCumulativeRewardPerToken.sub(
                            previousCumulatedRewardPerToken[_account]
                        )
                    )
                    .div(PRECISION)
            );

    
    }

    function stakedAmounts(address _account) private view returns (uint256) {
        return coreVault.balanceOf(_account);
    }
}
