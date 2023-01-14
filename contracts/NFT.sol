// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract MiPrimerNft is
    Initializable,
    PausableUpgradeable,
    ERC721Upgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    using Strings for uint256;

    uint256 nftTotal;
    bool[30] nftIds;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /*constructor() /**ERC721("MiPrimerNft", "MPRNFT")  {
        // _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _grantRole(PAUSER_ROLE, msg.sender);
        // _grantRole(MINTER_ROLE, msg.sender);
    }*/

    function initialize() public initializer {
        __ERC721_init("Mi Primer NFT", "MPRNFT");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        nftTotal = 0;
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function _baseURI() internal pure override returns (string memory) {
        //return "ipfs://CREA UN CID EN IPFS/";
    }

    function pause() public {
        _pause();
    }

    function unpause() public {
        _unpause();
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return (
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : ""
        );
    }

    function safeMint(address to, uint256 id) public {
        // Se hacen dos validaciones
        // 1 - Dicho id no haya sido acuñado antes
        // 2 - Id se encuentre en el rando inclusivo de 1 a 30
        //      * Mensaje de error: "Public Sale: id must be between 1 and 30"
        require(
            (id > 0) && (id <= 30),
            "Public Sale: id must be between 1 and 30"
        );

        nftIds[id - 1] = true;
        nftTotal++;

        _safeMint(to, id);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
