// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {TokenNFT} from "src/TokenNFT.sol";

contract DeployMyNFT is Script {
    string baseUri = "ipfs://QmExample";

    function run() public returns (TokenNFT) {

        vm.startBroadcast();

        TokenNFT nft = new TokenNFT(msg.sender, baseUri);

        vm.stopBroadcast();

        return nft;
    }
}
