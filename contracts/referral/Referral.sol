// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IReferral.sol";
import "./../ac/Ac.sol";

contract Referral is IReferral, Ac {
    struct Tier {
        uint256 totalRebate; // e.g. 2400 for 24%
        uint256 discountShare; // 5000 for 50%/50%, 7000 for 30% rebates/70% discount
    }

    uint256 public constant BASIS_POINTS = 10000;
    // TODO: specifiy this
    bytes32 public constant DEFAULT_CODE = bytes32("dei");

    mapping(address => uint256) public referrerDiscountShares; // to  default value in tier
    mapping(address => uint256) public referrerTiers; // link between user <> tier
    mapping(uint256 => Tier) public tiers;

    mapping(bytes32 => address) public codeOwners;
    mapping(address => bytes32) public traderReferralCodes;

    event SetTraderReferralCode(address account, bytes32 code);
    event SetTier(uint256 tierId, uint256 totalRebate, uint256 discountShare);
    event SetReferrerTier(address referrer, uint256 tierId);
    event SetReferrerDiscountShare(address referrer, uint256 discountShare);
    event RegisterCode(address account, bytes32 code);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event GovSetCodeOwner(bytes32 code, address newAccount);

    event IncreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );

    event DecreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );

    constructor() Ac(address(0)) {
        codeOwners[DEFAULT_CODE] = address(this);
    }

    function setTier(
        uint256 _tierId,
        uint256 _totalRebate,
        uint256 _discountShare
    ) external onlyAdmin {
        require(_totalRebate <= BASIS_POINTS, "Referral: invalid totalRebate");
        require(
            _discountShare <= BASIS_POINTS,
            "Referral: invalid discountShare"
        );

        Tier memory tier = tiers[_tierId];
        tier.totalRebate = _totalRebate;
        tier.discountShare = _discountShare;
        tiers[_tierId] = tier;
        emit SetTier(_tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(
        address _referrer,
        uint256 _tierId
    ) external onlyAdmin {
        referrerTiers[_referrer] = _tierId;
        emit SetReferrerTier(_referrer, _tierId);
    }

    function setReferrerDiscountShare(
        address _account,
        uint256 _discountShare
    ) external onlyAdmin {
        require(
            _discountShare <= BASIS_POINTS,
            "Referral: invalid discountShare"
        );

        referrerDiscountShares[_account] = _discountShare;
        emit SetReferrerDiscountShare(_account, _discountShare);
    }

    function setTraderReferralCode(
        address _account,
        bytes32 _code
    ) external onlyAdmin {
        _setTraderReferralCode(_account, _code);
    }

    function setTraderReferralCodeByUser(bytes32 _code) external {
        _setTraderReferralCode(msg.sender, _code);
    }

    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "Referral: invalid _code");
        require(
            codeOwners[_code] == address(0),
            "Referral: code already exists"
        );

        codeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    /**This function is designed to change the owner address of a specific code.
     * Only the original owner of the code has the authority to change the owner
     * address of the code. */
    function setCodeOwner(bytes32 _code, address _newAccount) external {
        require(_code != bytes32(0), "Referral: invalid _code");

        address account = codeOwners[_code];
        require(msg.sender == account, "Referral: forbidden");

        codeOwners[_code] = _newAccount;
        emit SetCodeOwner(msg.sender, _newAccount, _code);
    }

    function govSetCodeOwner(
        bytes32 _code,
        address _newAccount
    ) external onlyAdmin {
        require(_code != bytes32(0), "Referral: invalid _code");

        codeOwners[_code] = _newAccount;
        emit GovSetCodeOwner(_code, _newAccount);
    }

    function getTraderReferralInfo(
        address _account
    ) public view returns (bytes32, address) {
        bytes32 code = traderReferralCodes[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
        return (code, referrer);
    }

    function _setTraderReferralCode(address _account, bytes32 _code) private {
        traderReferralCodes[_account] = _code;
        emit SetTraderReferralCode(_account, _code);
    }

    function getCodeOwners(
        bytes32[] memory _codes
    ) public view returns (address[] memory) {
        address[] memory owners = new address[](_codes.length);

        for (uint256 i = 0; i < _codes.length; i++) {
            bytes32 code = _codes[i];
            owners[i] = codeOwners[code];
        }

        return owners;
    }

    function emitDecreasePositionReferral(
        address _account,
        bytes32 _referralCode,
        uint256 _sizeDelta,
        uint256 _marginFeeBasisPoints
    ) external onlyController {
        (bytes32 referralCode, address referrer) = getTraderReferralInfo(
            _account
        );

        if (referralCode == bytes32(0)) {
            require(codeOwners[_referralCode] != address(0), "invalid code");
            _setTraderReferralCode(_account, _referralCode);
            referralCode = _referralCode;
        }

        emit DecreasePositionReferral(
            _account,
            _sizeDelta,
            _marginFeeBasisPoints,
            referralCode,
            referrer
        );
    }

    function emitIncreasePositionReferral(
        address _account,
        bytes32 _referralCode,
        uint256 _sizeDelta,
        uint256 _marginFeeBasisPoints
    ) external onlyController {
        (bytes32 referralCode, address referrer) = getTraderReferralInfo(
            _account
        );

        if (referralCode == bytes32(0)) {
            require(codeOwners[_referralCode] != address(0), "invalid code");
            _setTraderReferralCode(_account, _referralCode);
            referralCode = _referralCode;
        }

        emit IncreasePositionReferral(
            _account,
            _sizeDelta,
            _marginFeeBasisPoints,
            referralCode,
            referrer
        );
    }
}
