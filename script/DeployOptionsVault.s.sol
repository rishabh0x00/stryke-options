// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/OptionsVault.sol";

/**
 * @title DeployOptionsVault
 * @notice This script deploys the OptionsVault contract using parameters provided in the .env file.
 * @dev Required .env variables:
 *  - PRIVATE_KEY: Deployer's private key.
 *  - UNISWAP_NFT_MANAGER: Address of the Uniswap NFT Manager.
 *  - UNISWAP_V3_FACTORY: Address of the Uniswap V3 Factory.
 *  - OPTION_TOKEN_IMPLEMENTATION: Address of the deployed OptionToken implementation.
 */
contract DeployOptionsVault is Script {
    function run() external {
        // Read environment variables.
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address uniswapNFTManagerAddress = vm.envAddress("UNISWAP_NFT_MANAGER");
        address uniswapV3FactoryAddress = vm.envAddress("UNISWAP_V3_FACTORY");
        address optionTokenImplementationAddress = vm.envAddress("OPTION_TOKEN_IMPLEMENTATION");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy OptionsVault contract with the provided addresses.
        OptionsVault optionsVault = new OptionsVault(
            uniswapNFTManagerAddress,
            uniswapV3FactoryAddress,
            optionTokenImplementationAddress
        );

        console.log("OptionsVault deployed at:", address(optionsVault));

        vm.stopBroadcast();
    }
}
