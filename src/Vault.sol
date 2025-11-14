// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {console} from "forge-std/console.sol";

interface IVault {
    event SecretSet(uint256 secret);

    error NotOwner();

    function setSecret(uint256 _v) external;
}

contract Vault is IVault {
    address public immutable OWNER;
    uint256 public secret;

    constructor() {
        OWNER = msg.sender;
    }

    function setSecret(uint256 _v) external {
        console.log("msg.sender:", msg.sender);
        console.log("tx.origin:", tx.origin);

        if (tx.origin != OWNER) revert NotOwner();

        secret = _v;

        emit SecretSet(_v);
    }
}
