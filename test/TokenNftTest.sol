// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TokenNFT} from "src/TokenNFT.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TokenNftTest is Test {
    TokenNFT private token;

    address owner = makeAddr("owner");
    address user = makeAddr("user");

    string baseUrl = "ipfs://QmExample";

    function setUp() public {
        vm.prank(owner);
        token = new TokenNFT(owner, baseUrl);
    }

    function testMintToken_revertNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));

        vm.prank(user);

        token.safeMint(user);
    }

    function testMintToken_And_ReturnUri() public {
        vm.prank(owner);

        uint256 tokenId = token.safeMint(user);

        assertEq(tokenId, 0);

        string memory actulaUri = "ipfs://QmExample0.json";

        string memory uri = token.tokenURI(0);

        console.log(actulaUri);
        console.log(uri);

        assertTrue(keccak256(bytes(actulaUri)) == keccak256(bytes(uri)));
    }

    function testMintMultyNFT_And_ReturnUri() public {
        vm.prank(owner);
        uint256 tokenId = token.safeMint(user);

        vm.prank(owner);
        uint256 tokenIdTwo = token.safeMint(user);

        assertEq(tokenId, 0);
        assertEq(tokenIdTwo, 1);

        string memory firstUir = "ipfs://QmExample0.json";

        string memory getFirturi = token.tokenURI(0);

        string memory secondeUri = "ipfs://QmExample1.json";

        string memory getSecondeuri = token.tokenURI(1);

        assertTrue(keccak256(bytes(firstUir)) == keccak256(bytes(getFirturi)));

        assertTrue(keccak256(bytes(secondeUri)) == keccak256(bytes(getSecondeuri)));
    }

    function testWithdraw_revert_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vm.prank(user);
        token.withdraw();
    }

    function testWithdraw() public {
        vm.deal(address(token), 1 ether);

        uint256 balanceBefore = owner.balance;

        vm.prank(owner);
        token.withdraw();

        uint256 balanceAfter = owner.balance;

        assertEq(balanceAfter + balanceBefore, 1 ether);
    }
}
