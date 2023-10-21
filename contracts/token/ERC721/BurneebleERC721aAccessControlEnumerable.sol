// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.14;

// =============================================
//    BurneebleERC721aAccessControlEnumerable
// =============================================
// The BurneebleERC721a contract is designed
//
// Properties:
// - `constructor`: 
// =============================================

/**
 * @title BurneebleERC721aAccessControlEnumerable
 * @author Burneeble
 */

//  =============================================
//               (        )                 (
//    (          )\ )  ( /(             (   )\ )
//  ( )\     (  (()/(  )\()) (    (   ( )\ (()/(  (
//  )((_)    )\  /(_))((_)\  )\   )\  )((_) /(_)) )\
// ((_)_  _ ((_)(_))   _((_)((_) ((_)((_)_ (_))  ((_)
//  | _ )| | | || _ \ | \| || __|| __|| _ )| |   | __|
//  | _ \| |_| ||   / | .` || _| | _| | _ \| |__ | _|
//  |___/ \___/ |_|_\ |_|\_||___||___||___/|____||___|
//
//  If you experience issues or have questions, please reach out for support.
//  Website: https://burneeble.com
//
//  =============================================

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface IBurneebleERC721A is IERC721A {
    function setBaseUri(string memory _baseUri) external;

    function setUriSuffix(string memory _uriSuffix) external;

    function setRevealed(bool _revealed) external;

    function setPaused(bool _paused) external;

    function setPreRevealUri(string memory _preRevealUri) external;

    function setMintPrice(uint256 _mintPrice) external;

    function setMaxMintAmountPerTrx(uint256 _maxAmount) external;

    function setMaxMintAmountPerAddress(uint256 _maxAmount) external;

    function withdrawBalance() external;

    function mint(uint256 _mintAmount) external payable;

    function grantAdminRole(address account) external;

    function revokeAdminRole(address account) external;

    function changeOwner(address newOwner) external;
}


contract BurneebleERC721A is ERC721A, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes4 public constant IBURNEEBLE_ERC721A_INTERFACE_ID =
        type(IBurneebleERC721A).interfaceId;

    uint256 public maxSupply;
    uint256 public mintPrice;

    string public baseUri = "";
    string public uriSuffix = ".json";
    string public preRevealUri = "";
    bool public revealed = false;
    bool public paused = true;

    uint256 public maxMintAmountPerTrx = 5;
    uint256 public maxMintAmountPerAddress = 20;
    mapping(address => uint256) public totalMintedByAddress;

    address public contractOwner;

    /**
     *  @notice BurneebleERC721 constructor
     *  @param _tokenName Token name
     *  @param _tokenName Token symbol
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) ERC721A(_tokenName, _tokenSymbol) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
         
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        contractOwner = msg.sender;
    }

    /**
     *  @dev Checks if caller can mint
     */
    modifier canMint(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceed!");
        require(
            _mintAmount <= maxMintAmountPerTrx,
            "Exceeded maximum total amount per trx!"
        );
        require(
            totalMintedByAddress[msg.sender] + _mintAmount <=
                maxMintAmountPerAddress,
            "Exceeded maximum total amount per address!"
        );
        _;
    }

    /**
     *  @dev Checks if caller provided enough funds for minting
     */
    modifier enoughFunds(uint256 _mintAmount) {
        require(msg.value >= _mintAmount * mintPrice, "Insufficient funds!");
        _;
    }

    modifier active() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier requireOwner(address _account) {
    require(hasRole(DEFAULT_ADMIN_ROLE, _account), "Unauthorized");
    _;
    }

    modifier requireAdmin(address _account) {
    require(hasRole(ADMIN_ROLE, _account), "Unauthorized");
    _;
    }

    /**
    * @dev Grants the admin role to a specific user.
    * Can only be called by users with the DEFAULT_ADMIN_ROLE (the owner).
    * @param account The address of the user to grant the admin role to.
    */
    function grantAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, account);
    }

    /**
    * @dev Revokes the admin role from a specific user.
    * Can only be called by users with the DEFAULT_ADMIN_ROLE (the owner).
    * @param account The address of the user from whom to revoke the admin role.
    */
    function revokeAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, account);
    }

    /**
    * @notice Changes the owner of the contract and assigns the DEFAULT_ADMIN_ROLE to the new owner.
    * Can only be called by the current owner.
    * @param newOwner The address of the new owner.
    */
    function changeOwner(address newOwner) public requireOwner(msg.sender) {
        require(newOwner != address(0), "Invalid new owner address");

        // Assign DEFAULT_ADMIN_ROLE to the new owner
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);

        // Remove DEFAULT_ADMIN_ROLE from the current owner
        revokeRole(DEFAULT_ADMIN_ROLE, contractOwner);

        // Update the contract's owner
        contractOwner = newOwner;
    }

    /**
     *  @notice Sets new base URI
     *  @param _baseUri New base URI to be set
     */
    function setBaseUri(string memory _baseUri) public requireAdmin(msg.sender) {
        baseUri = _baseUri;
    }

    /**
     *  @notice Sets new URI suffix
     *  @param _uriSuffix New URI suffix to be set
     */
    function setUriSuffix(string memory _uriSuffix) public requireAdmin(msg.sender) {
        uriSuffix = _uriSuffix;
    }

    /**
     *  @notice Reveals (or unreveals) the collection
     *  @param _revealed New revealed value to be set. True if revealed, false otherwise
     */
    function setRevealed(bool _revealed) public requireAdmin(msg.sender) {
        revealed = _revealed;
    }

    /**
     * @notice Change paused state
     * @param _paused Paused state
     */
    function setPaused(bool _paused) public requireAdmin(msg.sender) {
        paused = _paused;
    }

    /**
     *  @notice Sets new pre-reveal URI
     *  @param _preRevealUri New pre-reveal URI to be used
     */
    function setPreRevealUri(string memory _preRevealUri) public requireAdmin(msg.sender) {
        preRevealUri = _preRevealUri;
    }

    /**
     *  @notice Allows owner to set a new mint price
     *  @param _mintPrice New mint price to be set
     */
    function setMintPrice(uint256 _mintPrice) public requireAdmin(msg.sender) {
        mintPrice = _mintPrice;
    }

    /**
     *  @notice Allows owner to set the max number of mintable items in a single transaction
     *  @param _maxAmount Max amount
     */
    function setMaxMintAmountPerTrx(uint256 _maxAmount) public requireAdmin(msg.sender) {
        maxMintAmountPerTrx = _maxAmount;
    }

    /**
     *  @notice Allows owner to set the max number of items mintable per wallet
     *  @param _maxAmount Max amount
     */
    function setMaxMintAmountPerAddress(uint256 _maxAmount) public requireAdmin(msg.sender) {
        maxMintAmountPerAddress = _maxAmount;
    }

    /**
     *  @notice Withdraws contract balance to onwer account
     */
    function withdrawBalance() public virtual requireOwner(msg.sender) {
        (bool success, ) = payable(contractOwner).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    /**
     *  @inheritdoc ERC721A
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     *  @inheritdoc ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     *  @inheritdoc ERC721A
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token ID do es not exist.");

        // Checks if collection is revealed
        if (!revealed) return preRevealUri;

        // Evaluating full URI for the specified ID
        return string.concat(_baseURI(), _tokenId.toString(), uriSuffix);
    }

    /**
     *  @notice Mints one or more items
     */
    function mint(uint256 _mintAmount)
        public
        payable
        virtual
        canMint(_mintAmount)
        enoughFunds(_mintAmount)
        active
        nonReentrant
    {
        _safeMint(_msgSender(), _mintAmount);
        totalMintedByAddress[_msgSender()] += _mintAmount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IBurneebleERC721A).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}