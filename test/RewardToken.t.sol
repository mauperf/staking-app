// SPDX-License-Identifier: MIT

pragma solidity 0.8.37;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Test} from "forge-std/Test.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract TestRewardToken is Test {
    RewardToken rewardToken;

    address deployer = vm.addr(1);
    address user = vm.addr(2);

    function setUp() external {
        vm.prank(deployer);
        rewardToken = new RewardToken();
    }

    function mintTokens() public {
        uint256 _amount = 1 * 10**18;

        vm.prank(deployer);
        rewardToken.mint(user, _amount);
    }

    function testRevertMint_NotOwner() public {
        uint256 _amount = 1 * 10**18;
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        rewardToken.mint(user, _amount);
    }

    function testMint() public {
        uint256 _amount = 1 * 10**18;
        uint256 _balanceBefore = rewardToken.balanceOf(user);

        vm.prank(deployer);
        rewardToken.mint(user, _amount);

        uint256 _balanceAfter = rewardToken.balanceOf(user);

        assert(_balanceBefore == 0 && _balanceAfter != 0 && _balanceBefore + _amount == _balanceAfter);
    }

}