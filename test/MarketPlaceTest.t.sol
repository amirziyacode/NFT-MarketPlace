// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "src/MarketPlace.sol";
import {MockTokenNFT} from "./Mock/MockTokenNFT.sol";


contract MarketPlaceTest is Test {
    address payable private fee_market = payable(makeAddr("fee_market"));
    address private owner = makeAddr("owner");
    address private user = makeAddr("user");

    string private baseUrl = "ipfs://QmExample";

    MarketPlace private market;
    MockTokenNFT private nft;

    function setUp() public {
        nft = new MockTokenNFT(owner, baseUrl);
        market = new MarketPlace(fee_market);
    }

    function testConstructor() public view {
        assertEq(market.i_feesOwner(), fee_market);
    }

    // ==================== listingNFT  ====================

    function testListingNFT_Revert_NotOwner() public {
        vm.prank(owner);
        uint256 tokenId = nft.safeMint(user);
        uint256 listingPrice = 0.1 ether;

        address attacker = makeAddr("attacker");

        vm.prank(attacker);

        vm.expectRevert(MarketPlace.NFTMarketPlace__NotOwner.selector);

        market.listingNFT(address(nft), tokenId, listingPrice);
    }

    function testListingNFT_Revert_ZeroPrice() public {
        vm.prank(owner);
        uint256 tokenId = nft.safeMint(user);

        vm.prank(user);
        vm.expectRevert(MarketPlace.NFTMarketPlace__TokenValueCantBeZero.selector);
        
        market.listingNFT(address(nft), tokenId, 0);
    }

    function testListingNFT_Revert_isAlreadyListed() public {
       
        vm.prank(owner);
        uint256 tokenId = nft.safeMint(user);
        uint256 listingPrice = 0.1 ether;

        // listing nft for firs time !
        vm.prank(user);
        nft.approve(address(market), tokenId);

        vm.prank(user);
        market.listingNFT(address(nft), tokenId, listingPrice);

        vm.expectRevert(MarketPlace.NFTMarketPlace_TokenIsListed.selector);
        vm.prank(user);
        market.listingNFT(address(nft), tokenId, listingPrice);
    }

    function testListingNFT_Revert_IsNotApproved() public {
        
        vm.prank(owner);
        uint256 tokenId = nft.safeMint(user);
        uint256 listingPrice = 0.1 ether;

        vm.expectRevert(MarketPlace.NFTMarketPlace__TokenNotApproved.selector);

        vm.prank(user);
        market.listingNFT(address(nft),tokenId,listingPrice);
    }


    function testListingNFT() public {

        vm.prank(owner);
        uint256 tokenId = nft.safeMint(user);
        uint256 listingPrice = 0.1 ether;

        vm.startPrank(user);
 

        nft.approve(address(market), tokenId);

        // check TokenListed Event
        vm.expectEmit(true,false,false,true);
        emit MarketPlace.TokenListed(address(nft),tokenId,listingPrice,user);

        market.listingNFT(address(nft),tokenId,listingPrice);


        vm.stopPrank();

        uint256 expectPrice =  market.getPriceOfLitstedToken(address(nft),tokenId);
        address expectSeller = market.getSellerOfLitstedToken(address(nft),tokenId);

        assertEq(listingPrice,expectPrice);
        assertEq(user,expectSeller);
    }

    // ==================== Buy NFT  ====================
    
}
