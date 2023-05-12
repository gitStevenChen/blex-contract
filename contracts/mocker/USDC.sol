// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract USDC is ERC20, ERC20Burnable, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(address => uint256) public lastFaucetAt;

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _mint(msg.sender, initialSupply);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function batchMint(
        address[] memory tos,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < tos.length; i++) {
            address to = tos[i];
            _mint(to, amount);
        }
    }

    function burn(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _burn(to, amount);
    }

    function faucet() public {
        require(
            lastFaucetAt[_msgSender()] + 8 hours < block.timestamp,
            "cooldown duration not passed"
        );
        lastFaucetAt[_msgSender()] = block.timestamp;
        _mint(_msgSender(), 1000000 ether);
    }
}
