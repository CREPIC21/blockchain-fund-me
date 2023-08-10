// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // function to get a price of ETH in USD
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        /*
        Address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
        - https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum#Sepolia%20Testnet
        ABI
        */
        (, int answer, , , ) = priceFeed.latestRoundData();
        // Price of ETH in terms of USD - 2000.00000000
        return uint256(answer * 1e10);
    }

    // function to convert the msg.value to converted value based on the USD price
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // 1 ETH?
        // 2000_00000000
        uint256 ethPrice = getPrice(priceFeed);
        // (2000_000000000000000000 * 1_000000000000000000) / 1e18;
        // $2000 = 1 ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    // function getVersion() internal view returns (uint256) {
    //     return
    //         AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306)
    //             .version();
    // }
}
