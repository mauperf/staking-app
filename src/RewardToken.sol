// SPDX-License-Identifier: MIT

pragma solidity 0.8.37;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {

    constructor() ERC20("Reward Token", "RWD") Ownable(msg.sender) {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}