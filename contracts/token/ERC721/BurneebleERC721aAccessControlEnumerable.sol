// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.14;

// // =============================================
// //    BurneebleERC721aAccessControlEnumerable
// // =============================================
// // The BurneebleERC721a contract is designed
// //
// // Properties:
// // - `constructor`: 
// // =============================================

// /**
//  * @title BurneebleERC721aAccessControlEnumerable
//  * @author Burneeble
//  */

// //  =============================================
// //               (        )                 (
// //    (          )\ )  ( /(             (   )\ )
// //  ( )\     (  (()/(  )\()) (    (   ( )\ (()/(  (
// //  )((_)    )\  /(_))((_)\  )\   )\  )((_) /(_)) )\
// // ((_)_  _ ((_)(_))   _((_)((_) ((_)((_)_ (_))  ((_)
// //  | _ )| | | || _ \ | \| || __|| __|| _ )| |   | __|
// //  | _ \| |_| ||   / | .` || _| | _| | _ \| |__ | _|
// //  |___/ \___/ |_|_\ |_|\_||___||___||___/|____||___|
// //
// //  If you experience issues or have questions, please reach out for support.
// //  Website: https://burneeble.com
// //
// //  =============================================

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

    function mintForAddress(address receiver, uint256 _mintAmount)
        external
        payable;

    function ownerMintForAddress(uint256 _mintAmount, address _receiver)
        external;

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
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
         
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

    /**
     *  @notice Sets new base URI
     *  @param _baseUri New base URI to be set
     */
    function setBaseUri(string memory _baseUri) public onlyRole(ADMIN_ROLE) {
        baseUri = _baseUri;
    }

    /**
     *  @notice Sets new URI suffix
     *  @param _uriSuffix New URI suffix to be set
     */
    function setUriSuffix(string memory _uriSuffix) public onlyRole(ADMIN_ROLE) {
        uriSuffix = _uriSuffix;
    }

    /**
     *  @notice Reveals (or unreveals) the collection
     *  @param _revealed New revealed value to be set. True if revealed, false otherwise
     */
    function setRevealed(bool _revealed) public onlyRole(ADMIN_ROLE) {
        revealed = _revealed;
    }

    /**
     * @notice Change paused state
     * @param _paused Paused state
     */
    function setPaused(bool _paused) public onlyRole(ADMIN_ROLE) {
        paused = _paused;
    }

    /**
     *  @notice Sets new pre-reveal URI
     *  @param _preRevealUri New pre-reveal URI to be used
     */
    function setPreRevealUri(string memory _preRevealUri) public onlyRole(ADMIN_ROLE) {
        preRevealUri = _preRevealUri;
    }

    /**
     *  @notice Allows owner to set a new mint price
     *  @param _mintPrice New mint price to be set
     */
    function setMintPrice(uint256 _mintPrice) public onlyRole(ADMIN_ROLE) {
        mintPrice = _mintPrice;
    }

    /**
     *  @notice Allows owner to set the max number of mintable items in a single transaction
     *  @param _maxAmount Max amount
     */
    function setMaxMintAmountPerTrx(uint256 _maxAmount) public onlyRole(ADMIN_ROLE) {
        maxMintAmountPerTrx = _maxAmount;
    }

    /**
     *  @notice Allows owner to set the max number of items mintable per wallet
     *  @param _maxAmount Max amount
     */
    function setMaxMintAmountPerAddress(uint256 _maxAmount) public onlyRole(ADMIN_ROLE) {
        maxMintAmountPerAddress = _maxAmount;
    }

    /**
     *  @notice Withdraws contract balance to onwer account
     */
    function withdrawBalance() public virtual onlyRole(ADMIN_ROLE) {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
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

    function mintForAddress(address receiver, uint256 _mintAmount)
        public
        payable
        virtual
        enoughFunds(_mintAmount)
        active
    {
        require(
            _mintAmount <= maxMintAmountPerTrx,
            "Exceeded maximum total amount per trx!"
        );
        require(
            totalMintedByAddress[receiver] + _mintAmount <=
                maxMintAmountPerAddress,
            "Exceeded maximum total amount!"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            totalMintedByAddress[receiver]++;
        }

        _safeMint(receiver, _mintAmount);
    }

    /**
     * @notice Mints item for another address. (Reserved to contract owner)
     */
    function ownerMintForAddress(uint256 _mintAmount, address _receiver)
        public
        virtual
        onlyRole(ADMIN_ROLE)
    {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceed!");
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            TokenOwnership memory ownership = _ownershipOf(currentTokenId);

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IBurneebleERC721A).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}