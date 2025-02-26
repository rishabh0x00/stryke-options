// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/OptionToken.sol";

/**
 * @title DeployOptionToken
 * @notice A Foundry deployment script for the OptionToken contract.
 * @dev The script uses PRIVATE_KEY and RPC_URL from the .env file.
 */
contract DeployOptionToken is Script {
    function run() external {
        // Read the deployer's private key from the environment
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(privateKey);
        
        // Deploy the OptionToken implementation contract.
        OptionToken optionToken = new OptionToken();
        
        console.log("OptionToken implementation deployed at:", address(optionToken));
        
        // Stop broadcasting
        vm.stopBroadcast();
    }
}
