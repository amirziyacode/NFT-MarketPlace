// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;


import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract MarketPlace{

    

    // ==================== Erros  ====================
    error NFTMarketPlace__NotOwner();
    error NFTMarketPlace_TokenIsListed();
    error NFTMarketPlace__TokenValueCantBeZero();
    error NFTMarketPlace__TokenNotApproved();
    error NFTMarketPlace__TokenAddressInvalid();

    // ==================== Type Declarations  ====================
    struct Listing {
        address seller;
        uint256 price;
    }

    // ==================== State Variables  ====================

    mapping(address => mapping(uint256 => Listing)) private listings;

    // ==================== Events ====================
    event TokenListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 indexed tokenPrice,
        address seller);

    // ==================== Modifiers  ====================
    modifier onlyOwner(address nftAddress,uint256 tokenId) {
        if(IERC721(nftAddress).ownerOf(tokenId) != msg.sender){
            revert NFTMarketPlace__NotOwner();
        }
        _;
    }
    
    // ==================== Externla Functions  ====================
        /**
     * @notice Lists an NFT for sale on the marketplace.
     * @dev
     * - Caller must own the NFT (`onlyOwner` modifier).
     * - NFT must not already be listed (`price == 0` check).
     * - NFT must have a non-zero price.
     * - NFT must be approved for this marketplace via `getApproved` or `isApprovedForAll`.
     * - Stores listing details in `listings` mapping and emits `TokenListed` event.
     * @param _tokenId The unique identifier for the NFT within its contract.
     * @param _price The sale price for the NFT in wei.
     * @param nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__AlreadyListed Thrown if NFT is already listed.
     * @custom:error NFTMarketPlace__TokenValueCantBeZero Thrown if `tokenPrice` is zero.
     * @custom:error NFTMarketPlace__TokenNotApproved Thrown if NFT is not approved for the marketplace.
     * @custom:error NFTMarketPlace__TokenAddressInvalid Thrown Error if address of NFT is 0x0000000000....
     */
    function listingNFT(address nftAddress,uint256 _tokenId,uint256 _price) external  onlyOwner(msg.sender,_tokenId){
        
        if(nftAddress == address(0)){
            revert NFTMarketPlace__TokenAddressInvalid();
        }
        if (_price == 0){
            revert NFTMarketPlace__TokenValueCantBeZero();
        }
        
        if(listings[nftAddress][_tokenId].price != 0){
            revert NFTMarketPlace_TokenIsListed();
        }

        if (IERC721(nftAddress).getApproved(_tokenId) != address(this) && !IERC721(nftAddress).isApprovedForAll(msg.sender, address(this))) {
            revert NFTMarketPlace__TokenNotApproved();
        }
        
        
        listings[nftAddress][_tokenId].seller = msg.sender;
        listings[nftAddress][_tokenId].price = _price;

        emit TokenListed(nftAddress,_tokenId,_price,msg.sender);
    }

}