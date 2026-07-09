// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";

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
    error NFTMarketPlace__NotFeeOwner();
    error NFTMarketPlace__Not_FeebeZero();

    error NFTMarketPlace__WithdrawFaild();
    error NFTMarketPlace__NotValidAddress_To_Withdraw();

    // ==================== Type Declarations  ====================
    struct Listing {
        address seller;
        uint256 price;
    }

    // ==================== State Variables  ====================

    mapping(address => mapping(uint256 => Listing)) private listings;

    mapping(address => uint256) private proceeds;

    uint256 private fee = 25; // 2.5 %

    address payable public immutable i_feesOwner;

    // ==================== Events ====================
    event TokenListed(address indexed nftAddress, uint256 indexed tokenId, uint256 indexed tokenPrice, address seller);
    event TokenBuyer(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 feePrice,
        uint256 marketplaceFee,
        uint256 royaltyAmount
    );

    event UpdateListingPrice(
        address indexed nftAddress, uint256 indexed tokenId, address indexed seller, uint256 newPrice
    );

    event ListingCanceled(address indexed nftAddress, uint256 indexed tokenId, address indexed seller);
    // ==================== Modifiers  ====================
    modifier onlyOwner(address nftAddress, uint256 tokenId) {
        if (IERC721(nftAddress).ownerOf(tokenId) != msg.sender) {
            revert NFTMarketPlace__NotOwner();
        }
        _;
    }

    modifier onlyFeeOwner() {
        if (msg.sender != i_feesOwner) {
            revert NFTMarketPlace__NotFeeOwner();
        }
        _;
    }

    // ==================== Externla Functions  ====================

    constructor(address payable _feesOwner) {
        i_feesOwner = _feesOwner;
    }

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
     * @param _nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__AlreadyListed Thrown if NFT is already listed.
     * @custom:error NFTMarketPlace__TokenValueCantBeZero Thrown if `tokenPrice` is zero.
     * @custom:error NFTMarketPlace__TokenNotApproved Thrown if NFT is not approved for the marketplace.
     */
    function listingNFT(address _nftAddress, uint256 _tokenId, uint256 _price)
        external
        onlyOwner(_nftAddress, _tokenId)
    {
        if (_price == 0) {
            revert NFTMarketPlace__TokenValueCantBeZero();
        }

        if (listings[_nftAddress][_tokenId].price != 0) {
            revert NFTMarketPlace_TokenIsListed();
        }

        if (
            IERC721(_nftAddress).getApproved(_tokenId) != address(this)
                && !IERC721(_nftAddress).isApprovedForAll(msg.sender, address(this))
        ) {
            revert NFTMarketPlace__TokenNotApproved();
        }

        listings[_nftAddress][_tokenId].seller = msg.sender;
        listings[_nftAddress][_tokenId].price = _price;

        emit TokenListed(_nftAddress, _tokenId, _price, msg.sender);
    }

    /**
     * @notice Purchases a listed NFT from the marketplace.
     * @dev
     * - Buyer must send exactly the listing price in `msg.value`.
     * - NFT must be currently listed (`price > 0`).
     * - Caller cannot be the seller of the NFT.
     * - Fees are calculated as a percentage of the sale price and sent to `feesOwner`.
     * - Royalty  are calculated as a percentage of the sale price and sent to owner of NFT
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

        if (listing.price != msg.value) {
            revert NFTMarketPlace__IncorrectPrice();
        }

        if (listing.price == 0) {
            revert NFTMarketPlace__TokenIsNotListed();
        }

        // Calculate fees and  Royalty
        uint256 marketplaceFee = (listing.price * fee) / 1000;

        (address receiver, uint256 royaltyAmount) = IERC2981(_nftAddress).royaltyInfo(_tokenId, listing.price);

        uint256 sellerAmount = listing.price - marketplaceFee - royaltyAmount;

        delete listings[_nftAddress][_tokenId];

        // transfer NFT
        IERC721(_nftAddress).safeTransferFrom(listing.seller, msg.sender, _tokenId);

        // paid marketplaceFee
        proceeds[i_feesOwner] += marketplaceFee;

        // paid Royalty
        proceeds[receiver] += royaltyAmount;

        // paid seller
        proceeds[listing.seller] += sellerAmount;

        emit TokenBuyer(_nftAddress, _tokenId, msg.sender, marketplaceFee, royaltyAmount, sellerAmount);
    }

    /**
     * @notice Purchases cancel listed NFT from the marketplace.
     * @dev
     * only Owner of NFT can cancel the NFT Listing
     * @param _tokenId The unique identifier of the NFT within its contract.
     * @param _nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__TokenIsNotListed Thrown if the NFT is not listed for sale.
     */
    function cancelListing(address _nftAddress, uint256 _tokenId) external onlyOwner(_nftAddress, _tokenId) {
        Listing memory listing = listings[_nftAddress][_tokenId];

        if (listing.price == 0) {
            revert NFTMarketPlace__TokenIsNotListed();
        }

        delete listings[_nftAddress][_tokenId];

        emit ListingCanceled(_nftAddress, _tokenId, listing.seller);
    }

    /**
     * @notice Purchases Update the Price of  listed NFT from the marketplace.
     * @dev
     * only owner of NFT can change the price
     * @param _tokenId The unique identifier of the NFT within its contract.
     * @param _nftAddress The contract address of the ERC721 NFT.
     * @custom:error NFTMarketPlace__TokenIsNotListed Thrown if the NFT is not listed for sale.
     */
    function updatePriceListing(address _nftAddress, uint256 _tokenId, uint256 _newPrice)
        external
        onlyOwner(_nftAddress, _tokenId)
    {
        Listing storage listing = listings[_nftAddress][_tokenId];

        if (listing.price == 0) {
            revert NFTMarketPlace__TokenIsNotListed();
        }

        if (_newPrice == 0) {
            revert NFTMarketPlace__IncorrectPrice();
        }

        listing.price = _newPrice;

        emit UpdateListingPrice(_nftAddress, _tokenId, listing.seller, _newPrice);
    }

    /**
     * @notice Updates the marketplace fee percentage.
     * @dev
     * - Only callable by the current `feesOwner` (see `onlyFeeOwner` modifier).
     * - `newFees` must be greater than zero.
     * - Fees are stored as a whole number representing a percentage (e.g., 5 = 5%).
     * @param newFees The new marketplace fee percentage to set.
     * @custom:error NFTMarketPlace__Not_FeebeZero Thrown if `newFees` is zero.
     */
    function changeFees(uint256 newFees) external onlyFeeOwner {
        if (newFees == 0) {
            revert NFTMarketPlace__Not_FeebeZero();
        }
        fee = newFees;
    }

    /**
     * @notice withdraw all amount fee royaltyAmount and seller Amout.
     * @dev
     * for withdraw all fee and fee royaltyAmount and seller Amout
     * we calling call function and given zero to address of sender
     * @custom:error NFTMarketPlace__WithdrawFaild Thrown if transfer faild
     * @custom:error NFTMarketPlace__NotValidAddress_To_Withdraw if address is not in proceeds
     *
     */
    function withdrawProceeds() external nonReentrant {
        uint256 amount = proceeds[msg.sender];

        if (amount == 0) {
            revert NFTMarketPlace__NotValidAddress_To_Withdraw();
        }

        proceeds[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert NFTMarketPlace__WithdrawFaild();
        }
    }

    // ==================== Getter Functions ====================
    
    function getPriceOfLitstedToken(address _nftAddress,uint256 _tokenId) external view returns(uint256){
        return listings[_nftAddress][_tokenId].price;
    }

    function getSellerOfLitstedToken(address _nftAddress,uint256 _tokenId) external view returns(address){
        return listings[_nftAddress][_tokenId].seller;
    }
}
