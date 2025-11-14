// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Vault, IVault} from "@/Vault.sol";
import {TrickOwner} from "@/TrickOwner.sol";
import {console} from "forge-std/console.sol";

contract VaultTest is Test {
    Vault public vault;
    TrickOwner public trickOwner;
    address public immutable owner = address(1);
    address public immutable badActor = address(0xBAD);

    function setUp() public {
        vm.prank(owner);
        vault = new Vault();

        vm.label(address(vault), "Vault");

        console.log("Owner of Vault:", vault.OWNER());

        trickOwner = new TrickOwner(address(vault));

        vm.label(address(trickOwner), "TrickOwner");
    }

    function testSetSecretByOwner() public {
        // Arrange
        uint256 secretValue = 42;

        // Act
        vm.broadcast(owner);
        vault.setSecret(secretValue);

        // Assert
        assertEq(vault.secret(), secretValue);
    }

    function testSetSecretByBadActorFails() public {
        // Arrange
        uint256 secretValue = 42;

        // Act & Assert
        vm.broadcast(badActor);
        vm.expectRevert(abi.encodeWithSelector(IVault.NotOwner.selector));
        vault.setSecret(secretValue);
    }

    function testTrickOwnerFails() public {
        // Arrange

        // Act & Assert
        vm.broadcast(badActor);
        vm.expectRevert(abi.encodeWithSelector(IVault.NotOwner.selector));
        trickOwner.trickOwner();
    }

    function testTrickOwnerSucceedsWhenOwnerCalls() public {
        // Arrange

        // Act
        vm.broadcast(owner);
        trickOwner.trickOwner();

        // Assert
        assertEq(vault.secret(), 0);
    }
}
