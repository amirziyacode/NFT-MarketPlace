// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {MarketPlace} from "src/MarketPlace.sol";

contract DeployMarketPlace is Script {

    function run() public returns (MarketPlace) {

        vm.startBroadcast();

        MarketPlace market = new MarketPlace(payable(msg.sender));

        vm.stopBroadcast();

        return market;
    }
}
