// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
With this contract we want:
- get funds from users
- withdraw funds
- set minimum funding value in USD
*/

// - https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
// - https://docs.chain.link/data-feeds/using-data-feeds#examine-the-sample-contract
// - as we are developing locally first we installed https://github.com/smartcontractkit/chainlink-brownie-contracts -> "https://github.com/smartcontractkit/chainlink-brownie-contracts",
// then we pointed in foundry.toml file to installed dependencies using remappings
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    // attaching PriceConverter library to all uint256, now all uint256 have access to functions inside the library
    // - example: msg.value.getConversionRate()
    using PriceConverter for uint256;

    // setting minimum value that can be funded
    uint256 public constant MINIMUM_USD = 5 * 1e18; // or 5e18

    // saving senders in a array
    address[] private s_funders;

    // mapping addresses to amounts
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;

    // variable for the address of the contract owner that will be set in the constructor once the contract is deployed
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        /*
        Allow users to send money $
        Have a minimum amount $ set to 5 USD
        */
        // msg.value will automaticaly be passed as a parameter to the getConversionRate() function as the function expects one parameter in our created PriceConverter library
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough ETH."
        ); // 1e18 = 1 ETH = 1000000000000000000 wei = 1 * 10 ** 18
        // adding sender to array of funders
        // populating our mapping -> funder to amountFunded
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] =
            s_addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner {
        // only change that we did is getting founders array length before executing for loop so we don't have to read it from storage every time in loop iteration which is gas expensive(each call to storage is 100 gas)
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Call failed.");
    }

    // only the owner can call this function - using modifier onlyOwner for checking purposes instead require directly in the function
    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Must be owner"); // checking if the owner is actually withdrawing the funds
        // setting the amount of each funder to 0 in our mapping
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reseting funders array by creating a new array with 0 entries
        s_funders = new address[](0);

        // withdraving the funds from the contract - there are 3 different ways(transfer, send, call -> https://solidity-by-example.org/sending-ether/
        /* 
        - transfer
        -- msg.sender = type(address)
        -- payable(msg.sender) = type(payable address
        */
        // payable(msg.sender).transfer(address(this).balance);

        /*
        - send
        */
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // - call -> recomended way
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Call failed.");
    }

    // Modifiers
    //- they allow us to create a keyword that we can put in the function declaration to add specific functionality
    modifier onlyOwner() {
        // require(msg.sender == owner, "Sender is not owner.");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // add what ever else executes in the function
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    /**
     * View / Pure functions (Getters)
     */

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

/**
 * check where the variables are being stored: forge inspect FundMe storageLayout
 * test:
 * - run anvil in one terminal
 * - deploy contract in another terminal: forge script script/DeployFundMe.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6 --broadcast
 * - now run: cast storage <contract_address> 2
 * - you can aslo run: cast storage <contract_address> // https://book.getfoundry.sh/reference/cast/cast-storage?highlight=cast%20storage#cast-storage
 */
