// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployMyNFT} from "script/DeployMyNFT.s.sol";
import {TokenNFT} from "src/TokenNFT.sol";

contract DeployMyNftTest is Test{

    function testDeployScript() public{
        DeployMyNFT nft = new DeployMyNFT();

       TokenNFT deployedAddress =  nft.run();

        assertTrue(address(deployedAddress) != address(0), "Deployment failed, address is zero");
        assertTrue(address(deployedAddress).code.length > 0, "Deployment failed, no code at address");
    }

}