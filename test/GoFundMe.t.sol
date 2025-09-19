// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/goFundMe.sol";

contract GoFundMeTest is Test {
    GoFundMe public gf;
    address deployer = address(0xABCD);
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        // give accounts some ETH
        vm.deal(deployer, 10 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        // deploy contract as deployer
        vm.prank(deployer);
        gf = new GoFundMe();
    }

    function testInitialOwner() public {
        assertEq(gf.owner(), deployer);
    }

    function testFundBelowMinimumReverts() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Must send >= 0.2 ETH"));
        gf.fundMe{value: 0.1 ether}();
    }

    function testFundSuccessAddsFunderAndAmount() public {
        vm.prank(alice);
        gf.fundMe{value: 0.5 ether}();

        assertEq(gf.getFunderAmount(alice), 0.5 ether);
        assertEq(gf.getFundersCount(), 1);
        assertEq(address(gf).balance, 0.5 ether);
    }

    function testMultipleFundersAndAmounts() public {
        vm.prank(alice);
        gf.fundMe{value: 0.3 ether}();

        vm.prank(bob);
        gf.fundMe{value: 0.4 ether}();

        assertEq(gf.getFunderAmount(alice), 0.3 ether);
        assertEq(gf.getFunderAmount(bob), 0.4 ether);
        assertEq(gf.getFundersCount(), 2);
    }

    function testWithdrawByOwnerReducesContractBalance() public {
        vm.prank(alice);
        gf.fundMe{value: 1 ether}();

        vm.prank(deployer);
        gf.withdrawToMe(0.5 ether);

        assertEq(address(gf).balance, 0.5 ether);
    }

    function testWithdrawAllByOwnerEmptiesContract() public {
        vm.prank(alice);
        gf.fundMe{value: 0.25 ether}();

        vm.prank(deployer);
        gf.withdrawAll();

        assertEq(address(gf).balance, 0);
    }

    function testWithdrawByNonOwnerReverts() public {
        vm.prank(alice);
        gf.fundMe{value: 1 ether}();

        vm.prank(bob);
        vm.expectRevert(bytes("Only owner"));
        gf.withdrawToMe(0.1 ether);
    }
}
