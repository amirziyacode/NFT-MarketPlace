// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract MarketPlace is ReentrancyGuard {
    IERC721 tokenNFT;
    // ==================== Erros  ====================
    error NFTMarketPlace__NotOwner();
    error NFTMarketPlace_TokenIsListed();
    error NFTMarketPlace__TokenValueCantBeZero();
    error NFTMarketPlace__TokenNotApproved();
    error NFTMarketPlace__TokenAddressInvalid();
    error NFTMarketPlace__TokenIsNotListed();
    error NFTMarketPlace__IncorrectPrice();
    error NFTMarketPlace__CanNotBuy_OwnToken();
    error NFTMarketPlace__SellerPaymentFailed();

    // ==================== Type Declarations  ====================
    struct Listing {
        address seller;
        uint256 price;
    }

    // ==================== State Variables  ====================

    mapping(address => mapping(uint256 => Listing)) private listings;
    uint256 private fee = 25; // 2.5 %

    // ==================== Events ====================
    event TokenListed(address indexed nftAddress, uint256 indexed tokenId, uint256 indexed tokenPrice, address seller);
    event TokenBuyer(address indexed nftAddress, uint256 indexed tokenId, address indexed buyer, uint256 tokenPrice);

    event UpdateListingPrice(address indexed nftAddress,uint256 indexed tokenId,address indexed seller,uint256 newPrice);

    event ListingCanceled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller
    );
    // ==================== Modifiers  ====================
    modifier onlyOwner(address nftAddress, uint256 tokenId) {
        if (IERC721(nftAddress).ownerOf(tokenId) != msg.sender) {
            revert NFTMarketPlace__NotOwner();
        }
        _;
    }

    // ==================== Externla Functions  ====================

    /**
     * @notice Lists an NFT for sale on the marketplace.
     * @dev
     * - Caller must own the NFT (`onlyOwner` modifier).
     * - NFT must not already be listed (`price != 0` check).
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
    function listingNFT(address nftAddress, uint256 _tokenId, uint256 _price) external onlyOwner(msg.sender, _tokenId) {
        if (nftAddress == address(0)) {
            revert NFTMarketPlace__TokenAddressInvalid();
        }
        if (_price == 0) {
            revert NFTMarketPlace__TokenValueCantBeZero();
        }

        if (listings[nftAddress][_tokenId].price != 0) {
            revert NFTMarketPlace_TokenIsListed();
        }

        if (
            IERC721(nftAddress).getApproved(_tokenId) != address(this)
                && !IERC721(nftAddress).isApprovedForAll(msg.sender, address(this))
        ) {
            revert NFTMarketPlace__TokenNotApproved();
        }

        listings[nftAddress][_tokenId].seller = msg.sender;
        listings[nftAddress][_tokenId].price = _price;

        emit TokenListed(nftAddress, _tokenId, _price, msg.sender);
    }

    /**
     * @notice Purchases a listed NFT from the marketplace.
     * @dev
     * - Buyer must send exactly the listing price in `msg.value`.
     * - NFT must be currently listed (`price > 0`).
     * - Caller cannot be the seller of the NFT.
     * - Fees are calculated as a percentage of the sale price and sent to `feesOwner`.
     * - Remaining payment is sent to the seller.
     * - State (listings mapping) is updated before making external calls to prevent reentrancy risks.
     * - NFT is transferred to the buyer after payments are processed.
     * @param _tokenId The unique identifier of the NFT within its contract.
     * @param _nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__TokenIsNotListed Thrown if the NFT is not listed for sale.
     * @custom:error NFTMarketPlace__IncorrectPrice Thrown if `msg.value` does not match listing price.
     * @custom:error NFTMarketPlace__CanNotBuy_OwnToken Thrown if the buyer is the seller of the NFT.
     * @custom:error NFTMarketPlace__SellerPaymentFailed Thrown if sending payment to seller fails.
     */
    function buyNFT(uint256 _tokenId, address _nftAddress) external payable nonReentrant {
        if (_nftAddress == address(0)) {
            revert NFTMarketPlace__TokenAddressInvalid();
        }

        Listing memory listing = listings[_nftAddress][_tokenId];

        if (msg.sender == listing.seller) {
            revert NFTMarketPlace__CanNotBuy_OwnToken();
        }

        if (msg.value <= 0 && listing.price != msg.value) {
            revert NFTMarketPlace__IncorrectPrice();
        }

        if (listing.price == 0) {
            revert NFTMarketPlace__TokenIsNotListed();
        }

        delete listings[_nftAddress][_tokenId];

        // transfer NFT
        IERC721(_nftAddress).safeTransferFrom(listing.seller, msg.sender, _tokenId);

        // send money for seller
        (bool sellerPaid,) = payable(listing.seller).call{value: msg.value}("");
        if (!sellerPaid) {
            revert NFTMarketPlace__SellerPaymentFailed();
        }

        emit TokenBuyer(_nftAddress, _tokenId, msg.sender, listing.price);
    }



    /**
     * @notice Purchases cancel listed NFT from the marketplace.
     * @dev
     * only Owner of NFT can cancel the NFT Listing
     * @param _tokenId The unique identifier of the NFT within its contract.
     * @param _nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__TokenIsNotListed Thrown if the NFT is not listed for sale.
     */
    function cancelListing(address _nftAddress,uint256 _tokenId) external  onlyOwner(_nftAddress,_tokenId) {
        
        Listing memory listing = listings[_nftAddress][_tokenId];

        if(listing.price == 0){
            revert NFTMarketPlace__TokenIsNotListed();
        }

        delete listings[_nftAddress][_tokenId];

        emit ListingCanceled(_nftAddress,_tokenId,listing.seller);
    }

    /**
     * @notice Purchases Update the Price of  listed NFT from the marketplace.
     * @dev
     * only owner of NFT can change the price
     * @param _tokenId The unique identifier of the NFT within its contract.
     * @param _nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__TokenIsNotListed Thrown if the NFT is not listed for sale.
     */
    function updatePriceListing(address _nftAddress,uint256 _tokenId,uint256 _newPrice) external  onlyOwner(_nftAddress,_tokenId){
        
        Listing storage listing = listings[_nftAddress][_tokenId];


        if(listing.price == 0){
            revert NFTMarketPlace__TokenIsNotListed();
        }

        if(_newPrice == 0){
            revert NFTMarketPlace__IncorrectPrice();
        }

        listing.price = _newPrice;

        emit UpdateListingPrice(_nftAddress,_tokenId,listing.seller,_newPrice);
    }


}
