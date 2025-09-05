// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBank {
    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);

    error InsufficientBalance(uint256 requested, uint256 available);
    error InvalidAmount(uint256 amount);
    error TransferFailed(address to, uint256 amount);

    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract Bank is IBank {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        if (msg.value == 0) revert InvalidAmount(msg.value);

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        // Check for valid amount and sufficient balance
        if (amount == 0) revert InvalidAmount(amount);
        if (amount > balances[msg.sender])
            revert InsufficientBalance(amount, balances[msg.sender]);

        // Interaction: transfer the amount to the sender
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed(msg.sender, amount);

        // Effects: update the balance
        unchecked {
            balances[msg.sender] -= amount;
        }

        emit Withdraw(msg.sender, amount);
    }
}
