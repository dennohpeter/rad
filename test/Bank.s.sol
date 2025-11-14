// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Bank, IBank} from "@/Bank.sol";
import {Attacker} from "@/Attacker.sol";
import {console} from "forge-std/console.sol";

contract BankTest is Test {
    Bank public bank;
    Attacker public attacker;
    address public constant OWNER = address(0xBEEF);
    address public constant ATTACKER = address(0xBAD);

    function setUp() public {
        vm.prank(OWNER);
        bank = new Bank();

        vm.prank(ATTACKER);
        attacker = new Attacker(address(bank));

        vm.label(address(bank), "Bank");
        vm.label(OWNER, "Bank Owner");
        vm.label(ATTACKER, "Attacker");
        vm.label(address(attacker), "Attacker Contract");
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
        uint256 initialBankBalance = 10 ether;
        uint256 attackerInitialBalance = 1 ether;

        // vm.deal(address(bank), initialBankBalance);
        _multiDeposits(10, 1 ether); // 10 users deposit 1 ether each
        assertEq(address(bank).balance, initialBankBalance);
        vm.deal(ATTACKER, attackerInitialBalance);

        // Act
        vm.prank(ATTACKER);
        attacker.attack{value: attackerInitialBalance}();

        // Assert
        // The bank's balance should be 0 after the attack
        assertEq(address(bank).balance, 0);
        // The attacker's balance should have increased by the bank's initial balance
        assertEq(ATTACKER.balance, attackerInitialBalance + initialBankBalance);

        console.log("Bank balance after attack    :", address(bank).balance);
        console.log("Attacker balance after attack:", ATTACKER.balance);
    }

    function testRewardByOwner() public {
        // Arrange
        address user = address(1);
        vm.label(user, "RewardedUser");

        uint256 rewardAmount = 1 ether;

        // Act
        vm.broadcast(OWNER);
        bank.reward(user, rewardAmount);

        // Assert
        assertEq(bank.balances(user), rewardAmount);
    }

    function testRewardByNonOwnerFails() public {
        // Arrange
        address user = address(1);
        vm.label(user, "RewardedUser");

        address badActor = address(0xDEAD);
        vm.label(badActor, "BadActor");

        uint256 rewardAmount = 1 ether;

        // Act & Assert
        vm.broadcast(badActor);
        vm.expectRevert(abi.encodeWithSelector(IBank.NotOwner.selector));
        bank.reward(user, rewardAmount);
    }

    function testTrickRewardByAttackerFails() public {
        // Arrange
        uint256 rewardAmount = 5 ether;

        // Act
        vm.broadcast(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(IBank.NotOwner.selector));
        attacker.trickReward(rewardAmount);

        // Assert
        assertEq(bank.balances(ATTACKER), 0);
    }

    function testTrickRewardByOwnerSucceeds() public {
        // Arrange
        uint256 rewardAmount = 5 ether;

        // Act
        vm.broadcast(OWNER);
        attacker.trickReward(rewardAmount);

        // Assert
        assertEq(bank.balances(ATTACKER), rewardAmount);
    }

    function _multiDeposits(uint256 n, uint256 amount) internal {
        for (uint256 i = 1; i <= n; i++) {
            // forge-lint: disable-next-line(unsafe-typecast)
            address user = address(uint160(i));
            vm.deal(user, amount);
            vm.prank(user);
            bank.deposit{value: amount}();
        }
    }
}
