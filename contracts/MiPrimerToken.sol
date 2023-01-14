// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyTokenMiPrimerToken is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() initializer {}

    constructor() ERC20("MyTokenMiPrimerToken", "MPRTKN") {}

    function initialize() public initializer {
        __ERC20_init("Mi Primer Token", "MPRTKN");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _mint(msg.sender, 1000000 * 10 ** decimals());

        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
    }

    function mint(address to, uint256 amount) public onlyOwner(MINTER_ROLE) {
        _mint(to, amount);
    }

     function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(MINTER_ROLE) {}
}
