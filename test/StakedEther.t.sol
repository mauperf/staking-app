// SPDX-License-Identifier: MIT

pragma solidity 0.8.37;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {StakedEther} from "../src/StakedEther.sol";

contract TestStakedEther is Test {
    StakedEther stkEther;

    address deployer = vm.addr(1);
    address user = vm.addr(2);
    address user2 = vm.addr(3);

    function setUp() external {
        vm.prank(deployer);
        stkEther = new StakedEther();
    }

    function mintTokens() public {
        uint256 _amount = 1 * 10**18;

        vm.prank(deployer);
        stkEther.mint(user, _amount);
    }

    function testRevertMint_NotOwner() public {
        uint256 _amount = 1 * 10**18;
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        stkEther.mint(user, _amount);
    }

    function testMint() public {
        uint256 _amount = 1 * 10**18;
        uint256 _balanceBefore = stkEther.balanceOf(user);

        vm.prank(deployer);
        stkEther.mint(user, _amount);

        uint256 _balanceAfter = stkEther.balanceOf(user);

        assert(_balanceBefore == 0 && _balanceAfter != 0 && _balanceBefore + _amount == _balanceAfter);
    }

    function testRevertBurn_NotOwner() public {
        mintTokens();
        uint256 _amount = 1 * 10**18;
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        stkEther.burn(user, _amount);
    }

    function testBurn() public {
        mintTokens();
        uint256 _amount = 1 * 10**18;
        vm.prank(deployer);
        stkEther.burn(user, _amount);
    }

    function testRevertTransfer_NonTransferable() public {
        mintTokens();
        uint256 _amount = 1 * 10**18;
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(StakedEther.NonTransferable.selector));
        stkEther.transfer(user2, _amount);
    }


}