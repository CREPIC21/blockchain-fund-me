// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

// https://book.getfoundry.sh/forge/cheatcodes -> Foundry cheatcodes

contract InteractionsTest is Test {
    FundMe fundMe;

    //https://book.getfoundry.sh/reference/forge-std/make-addr?highlight=makeAddr#makeaddr
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // us -> FundMeTest -> FundMe
        // fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // https://book.getfoundry.sh/cheatcodes/deal?highlight=deal#deal
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUserCanFundInteractions() public {
        // funding the contract using our scripts
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        // withdrawing from the contract using our scripts
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        // checking if the contract balance is equal to 0
        assert(address(fundMe).balance == 0);
        // vm.prank(USER);
        // vm.deal(USER, 1e18);
        // fundFundMe.fundFundMe(address(fundMe));

        // address funder = fundMe.getFunder(0);
        // assertEq(funder, USER);
    }
}

/**
 * RUNNING THE TEST
 * - forge test --mt testUserCanFundInteractions -vvvv
 */
