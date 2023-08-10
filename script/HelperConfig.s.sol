// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 1. Deploy mocks when we are on a local anvil chain
// 2. Keep track of contract address accross different chains
// Sepolia ETH/USD
// Mainnet ETH/USD

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    /*
    If we aare on local anvil, we deploy mocks, otherwise grab the existing address from the live network
    */
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        // https://chainlist.org/
        // https://docs.soliditylang.org/en/v0.8.19/units-and-global-variables.html
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
        // terminal command to run: forge test --fork-url $SEPOLIA_ALCHEMY_RPC_URL
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return ethConfig;
        // terminal command to run: forge test --fork-url $MAINNET_ALCHEMY_RPC_URL
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // price feed address

        // 1. Deploy the mocks(fake/dummy contract)
        // 2. Return the mock address

        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
        // terminal command to run: forge test
    }
}
