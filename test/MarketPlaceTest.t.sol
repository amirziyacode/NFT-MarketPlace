// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "src/MarketPlace.sol";
import {MockTokenNFT} from "./Mock/MockTokenNFT.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";

contract MarketPlaceTest is Test {
    address payable private fee_market = payable(makeAddr("fee_market"));
    address private owner = makeAddr("owner");
    address private user = makeAddr("user");

    string private baseUrl = "ipfs://QmExample";

    MarketPlace private market;
    MockTokenNFT private nft;

    uint256 tokenId;
    uint256 private constant LISTING_PRICE = 0.1 ether;

    function setUp() public {
        nft = new MockTokenNFT(owner, baseUrl);
        market = new MarketPlace(fee_market);

        vm.prank(owner);
        tokenId = nft.safeMint(user);
    }

    modifier ListingToken() {
        vm.startPrank(user);

        nft.approve(address(market), tokenId);

        market.listingNFT(address(nft), tokenId, LISTING_PRICE);

        vm.stopPrank();
        _;
    }

    function testConstructor() public view {
        assertEq(market.i_feesOwner(), fee_market);
    }

    // ==================== listingNFT  ====================

    function testListingNFT_Revert_NotOwner() public {
        address attacker = makeAddr("attacker");

        vm.prank(attacker);

        vm.expectRevert(MarketPlace.NFTMarketPlace__NotOwner.selector);

        market.listingNFT(address(nft), tokenId, LISTING_PRICE);
    }

    function testListingNFT_Revert_ZeroPrice() public {
        vm.prank(user);
        vm.expectRevert(MarketPlace.NFTMarketPlace__TokenValueCantBeZero.selector);

        market.listingNFT(address(nft), tokenId, 0);
    }

    function testListingNFT_Revert_isAlreadyListed() public ListingToken {
        // listing nft for seconde time !

        vm.expectRevert(MarketPlace.NFTMarketPlace_TokenIsListed.selector);
        vm.prank(user);
        market.listingNFT(address(nft), tokenId, LISTING_PRICE);
    }

    function testListingNFT_Revert_IsNotApproved() public {
        vm.expectRevert(MarketPlace.NFTMarketPlace__TokenNotApproved.selector);

        vm.prank(user);
        market.listingNFT(address(nft), tokenId, LISTING_PRICE);
    }

    function testListingNFT() public {
        vm.startPrank(user);

        nft.approve(address(market), tokenId);

        // check TokenListed Event
        vm.expectEmit(true, false, false, true);
        emit MarketPlace.TokenListed(address(nft), tokenId, LISTING_PRICE, user);

        market.listingNFT(address(nft), tokenId, LISTING_PRICE);

        vm.stopPrank();

        uint256 expectPrice = market.getPriceOfLitstedToken(address(nft), tokenId);
        address expectSeller = market.getSellerOfLitstedToken(address(nft), tokenId);

        assertEq(LISTING_PRICE, expectPrice);
        assertEq(user, expectSeller);
    }

    // ==================== Buy NFT  ====================
    function testBuyNFT_revert_invalidNFTAddress() public {
        vm.expectRevert(MarketPlace.NFTMarketPlace__TokenAddressInvalid.selector);
        market.buyNFT(0, address(0));
    }

    function testBuyNFT_revert_OwnerOfToken_CanNotBuyOwnToken() public ListingToken {
        vm.expectRevert(MarketPlace.NFTMarketPlace__CanNotBuy_OwnToken.selector);

        vm.prank(user);

        market.buyNFT(tokenId, address(nft));
    }

    function testBuyNFT_revert_IncorrectPrice() public ListingToken {
        vm.expectRevert(MarketPlace.NFTMarketPlace__IncorrectPrice.selector);

        market.buyNFT(tokenId, address(nft));
    }

    function testBuyNFT_revert_TokenIsNotListed() public {
        vm.expectRevert(MarketPlace.NFTMarketPlace__TokenIsNotListed.selector);

        market.buyNFT(0, address(nft));
    }

    function testBuyNFT() public ListingToken {
        address buyer = makeAddr("buyer");

        vm.deal(buyer, 1 ether);
        vm.deal(user, 1 ether);

        uint256 fee = 25; // 2.5 %

        uint256 marketplaceFee = (LISTING_PRICE * fee) / 1000;

        (address receiver, uint256 royaltyAmount) = IERC2981(nft).royaltyInfo(tokenId, LISTING_PRICE);

        uint256 expectSellerAmount = LISTING_PRICE - marketplaceFee - royaltyAmount;

        // check Event
        vm.expectEmit(true, false, true, true);
        emit MarketPlace.TokenBuyer(address(nft), tokenId, buyer, marketplaceFee, royaltyAmount, expectSellerAmount);

        vm.prank(buyer);
        market.buyNFT{value: 0.1 ether}(tokenId, address(nft));

        // check NFT is Tranfer to buyer !!!
        address expectBuyer = nft.ownerOf(tokenId);

        assertEq(expectBuyer, buyer);

        assertEq(market.getAmountOfProceeds(fee_market), marketplaceFee);
        assertEq(market.getAmountOfProceeds(receiver), royaltyAmount);
        assertEq(market.getAmountOfProceeds(user), expectSellerAmount);

        // delete lits in marketPlace
        assertEq(market.getPriceOfLitstedToken(address(nft), 0), 0);
        assertEq(market.getSellerOfLitstedToken(address(nft), 0), address(0));
    }

    // ==================== cancelListing  ====================

    function testCancelListing_revert_NotOwner() public ListingToken {
        vm.expectRevert(MarketPlace.NFTMarketPlace__NotOwner.selector);

        market.cancelListing(address(nft), tokenId);
    }

    function testCancelListing_revert_if_TokenNotListed() public {
        vm.expectRevert(MarketPlace.NFTMarketPlace__TokenIsNotListed.selector);

        vm.prank(user);
        market.cancelListing(address(nft), tokenId);
    }

    function testCancelListing() public ListingToken {
        vm.expectEmit(true, false, false, true);

        emit MarketPlace.ListingCanceled(address(nft), tokenId, user);

        vm.prank(user);
        market.cancelListing(address(nft), tokenId);

        assertEq(market.getPriceOfLitstedToken(address(nft), tokenId), 0);
        assertEq(market.getSellerOfLitstedToken(address(nft), tokenId), address(0));
    }

    // ==================== UpdatePriceListing  ====================

    function testUpdatePriceListing_revert_NotOwner() public ListingToken {
        vm.expectRevert(MarketPlace.NFTMarketPlace__NotOwner.selector);

        market.updatePriceListing(address(nft), tokenId, 0.5 ether);
    }

    function testUpdatePriceListing_revert_TokenIsNotListed() public {
        vm.expectRevert(MarketPlace.NFTMarketPlace__TokenIsNotListed.selector);

        vm.prank(user);
        market.updatePriceListing(address(nft), tokenId, 0.5 ether);
    }

    function testUpdatePriceListing_revert_IncorrectPrice() public ListingToken {
        vm.expectRevert(MarketPlace.NFTMarketPlace__IncorrectPrice.selector);

        vm.prank(user);
        market.updatePriceListing(address(nft), tokenId, 0);
    }

    function testUpdatePriceListing() public ListingToken {
        uint256 newPrice = 0.5 ether;

        vm.expectEmit(true, false, false, true);
        emit MarketPlace.UpdateListingPrice(address(nft), tokenId, user, newPrice);
        vm.prank(user);
        market.updatePriceListing(address(nft), tokenId, newPrice);

        assertEq(market.getPriceOfLitstedToken(address(nft), tokenId), newPrice);
    }

    // ==================== changeFees  ====================
    function testChangeFee_revert_NotFeeOwner() public {
        vm.expectRevert(MarketPlace.NFTMarketPlace__NotFeeOwner.selector);

        market.changeFees(300); // fee is 3 %;
    }

    function testChangeFee_revert_ZeroFee() public {
        vm.expectRevert(MarketPlace.NFTMarketPlace__Not_FeebeZero.selector);

        vm.prank(fee_market);
        market.changeFees(0);
    }

    function testChangeFee() public {
        // fee is 3 % now
        uint256 newFee = 300;

        vm.prank(fee_market);

        market.changeFees(300);

        uint256 getNewFee = market.getFee();

        assertEq(getNewFee, newFee);
    }

    // ==================== withdrawProceeds  ====================

    function testWithdrawProceeds_revert_if_address_is_no_MonyeToSend() public {
        vm.expectRevert(MarketPlace.NFTMarketPlace__NotValidAddress_To_Withdraw.selector);
        market.withdrawProceeds();
    }

    /**
     * @dev
     * for pass this we should mint a token and listed on marketPlace now we are already do it in setUpFunction
     * we list our nft in marketPalce and a buyyer buy this nft
     * and we want to withraw all  the fee for fee_marketPlace
     * and royalty evert time a buyyer buy it is send backe it
     * finaly we send a amount of priceOfNFT to seller and withdraw it
     */

    function testWithdrawProceeds() public ListingToken {
        address buyer = makeAddr("buyer");

        vm.deal(buyer, 1 ether);
        vm.deal(user, 1 ether);

        uint256 fee = 25; // 2.5 %

        uint256 marketplaceFee = (LISTING_PRICE * fee) / 1000;

        (address receiver, uint256 royaltyAmount) = IERC2981(nft).royaltyInfo(tokenId, LISTING_PRICE);

        uint256 expectSellerAmount = LISTING_PRICE - marketplaceFee - royaltyAmount;

        vm.prank(buyer);
        market.buyNFT{value: 0.1 ether}(tokenId, address(nft));

        // withdraw for user
        uint256 userBalanceBefore = user.balance; // 1 ether

        vm.expectEmit(true, false, false, true);

        emit MarketPlace.WithdrawProceeds(user, expectSellerAmount);

        vm.prank(user);
        market.withdrawProceeds();

        uint256 userBalanceAfter = user.balance; // 1 ether + expectSellerAmount

        assertEq(userBalanceAfter, userBalanceBefore + expectSellerAmount);

        // withdraw for fee_market

        uint256 balanceFeeMarketBefor = address(fee_market).balance;

        vm.expectEmit(true, false, false, true);

        emit MarketPlace.WithdrawProceeds(fee_market, marketplaceFee);

        vm.prank(fee_market);
        market.withdrawProceeds();

        uint256 balanceFeeMarketAfter = address(fee_market).balance;

        assertEq(balanceFeeMarketAfter, marketplaceFee + balanceFeeMarketBefor);

        // withdraw the artist of NFT

        uint256 balanceReceiverBefore = address(receiver).balance;

        vm.expectEmit(true, false, false, true);

        emit MarketPlace.WithdrawProceeds(receiver, royaltyAmount);

        vm.prank(receiver);
        market.withdrawProceeds();

        uint256 balanceReceiverAfter = address(receiver).balance;

        assertEq(balanceReceiverAfter, balanceReceiverBefore + royaltyAmount);
    }

    // ==================== Getter  ====================

    function testGetFee() public view {
        assertEq(market.getFee(), 25);
    }

    function test_GetPriceOfLitstedToken() public ListingToken {
        assertEq(market.getPriceOfLitstedToken(address(nft), tokenId), LISTING_PRICE);
    }

    function test_GeSellerOfLitstedToken() public ListingToken {
        assertEq(market.getSellerOfLitstedToken(address(nft), tokenId), user);
    }
}
