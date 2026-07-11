// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployMarketPlace} from "script/DeployMarketPlace.s.sol";
import {MarketPlace} from "src/MarketPlace.sol";

contract DeployMarketPlaceTest is Test{

    function testDeployScript() public{
        DeployMarketPlace market = new DeployMarketPlace();

       MarketPlace deployedAddress =  market.run();

        assertTrue(address(deployedAddress) != address(0), "Deployment failed, address is zero");
        assertTrue(address(deployedAddress).code.length > 0, "Deployment failed, no code at address");
    }

}