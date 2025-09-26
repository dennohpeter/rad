// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank, IBank} from "@/Bank.sol";
import {Attacker} from "@/Attacker.sol";
import {console} from "forge-std/console.sol";

contract BankTest is Test {
    Bank public bank;

    function setUp() public {
        bank = new Bank();
    }

    function testDeposit() public {
        // Arrange
        address user = address(1);
        uint256 depositAmount = 1 ether;
        vm.deal(user, depositAmount);

        // Act
        vm.prank(user);
        bank.deposit{value: depositAmount}();

        // Assert
        assertEq(bank.balances(user), depositAmount);
    }

    function testWithdraw() public {
        // Arrange
        address user = address(1);
        uint256 depositAmount = 1 ether;
        vm.deal(user, depositAmount);

        vm.prank(user);
        bank.deposit{value: depositAmount}();

        // Act
        vm.prank(user);
        bank.withdraw(depositAmount);

        // Assert
        assertEq(bank.balances(user), 0);
    }

    function testWithdrawInsufficientBalance() public {
        // Arrange
        address user = address(1);
        uint256 withdrawAmount = 1 ether;

        // Act & Assert
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IBank.InsufficientBalance.selector,
                withdrawAmount,
                0
            )
        );
        bank.withdraw(withdrawAmount);
    }

    function testDepositInvalidAmount() public {
        // Arrange
        address user = address(1);
        uint256 depositAmount = 0;

        // Act & Assert
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IBank.InvalidAmount.selector, depositAmount)
        );
        bank.deposit{value: depositAmount}();
    }

    function testWithdrawInvalidAmount() public {
        // Arrange
        address user = address(1);
        uint256 withdrawAmount = 0;

        // Act & Assert
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IBank.InvalidAmount.selector, withdrawAmount)
        );
        bank.withdraw(withdrawAmount);
    }

    function testReentrancyAttack() public {
        // Arrange
        address attackerEOA = address(1);
        uint256 initialBankBalance = 10 ether;
        uint256 attackerInitialBalance = 1 ether;

        vm.deal(address(bank), initialBankBalance);
        vm.deal(attackerEOA, attackerInitialBalance);

        Attacker attacker = new Attacker(address(bank));

        // Act
        vm.prank(attackerEOA);
        attacker.attack{value: attackerInitialBalance}();

        // Assert
        // The bank's balance should be 0 after the attack
        assertEq(address(bank).balance, 0);
        // The attacker's balance should have increased by the bank's initial balance
        assertEq(
            attackerEOA.balance,
            attackerInitialBalance + initialBankBalance
        );

        console.log("Bank balance after attack    :", address(bank).balance);
        console.log("Attacker balance after attack:", attackerEOA.balance);
    }
}
