// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

// https://book.getfoundry.sh/forge/cheatcodes -> Foundry cheatcodes

contract FundMeTest is Test {
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

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        // https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#expectrevert
        vm.expectRevert(); // hey, the next line should revert, it should fail
        fundMe.fund(); // sending 0 value when we should send 5e18
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be send by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); // The next TX will be send by USER
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER); // The next TX will be send by USER
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // adding modifier in function declaration so we don't have to repeat the same code over and over
        // vm.prank(USER); // The next TX will be send by USER
        // fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert(); // the line fundMe.withdraw(); should revert, it should fail
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        uint256 gasStart = gasleft(); // example: 1000

        vm.txGasPrice(GAS_PRICE); // https://book.getfoundry.sh/cheatcodes/tx-gas-price?highlight=txGasPrice#txgasprice
        vm.prank(fundMe.getOwner()); // spend 200 gas
        fundMe.withdraw();

        uint256 gasEnd = gasleft(); // left 800 gas
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithDrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numbersOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // creating multiple funders which are funding the contract
        for (uint160 i = startingFunderIndex; i < numbersOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            hoax(address(1), SEND_VALUE); // https://book.getfoundry.sh/reference/forge-std/hoax?highlight=hoax#hoax
            fundMe.fund{value: SEND_VALUE}();
        }

        // Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    // using cheaperWithdraw() in the code as it is more gas efficient
    function testWithDrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numbersOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // creating multiple funders which are funding the contract
        for (uint160 i = startingFunderIndex; i < numbersOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            hoax(address(1), SEND_VALUE); // https://book.getfoundry.sh/reference/forge-std/hoax?highlight=hoax#hoax
            fundMe.fund{value: SEND_VALUE}();
        }

        // Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}

/* ### TEST COMMANDS ###
forge test
forge test --fork-url $SEPOLIA_ALCHEMY_RPC_URL
forge test --mt testPriceFeedVersionIsAccurate
forge test --mt testPriceFeedVersionIsAccurate -vv
forge test --mt testPriceFeedVersionIsAccurate -vvv
forge test --mt testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_ALCHEMY_RPC_URL
forge test --mt testPriceFeedVersionIsAccurate -vvvv --fork-url $SEPOLIA_ALCHEMY_RPC_URL
forge coverage --fork-url $SEPOLIA_ALCHEMY_RPC_URL
forge snapshot
forge snapshot --mt testWithDrawFromMultipleFunder -> creates a new file with data on how much gas was spent for testing the function
chisel -> opens Solidity environment in terminal https://book.getfoundry.sh/reference/chisel/?highlight=chisel#chisel
*/

/*
1. Unit: Testing a single function
2. Integration: Testing multiple functions
3. Forked: Testing on a forked network
4. Staging: Testing on a live network (testnet or mainnet)
*/
