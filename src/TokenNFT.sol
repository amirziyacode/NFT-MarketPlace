// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract TokenNFT is ERC721, Ownable {
    // ==================== State Varibales ====================
    uint256 private _tokenId;
    string private baseURI;

    // ==================== External Functions ====================

    constructor(address owner, string memory _baseURI) ERC721("AvinToken", "ATK") Ownable(owner) {
        baseURI = _baseURI;
    }

    function safeMint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @notice Returns the token URI for a given tokenId.
     * @param tokenId The NFT's token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string.concat(baseURI, Strings.toString(tokenId), ".json");
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
