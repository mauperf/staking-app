// SPDX-License-Identifier: MIT

pragma solidity 0.8.37;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import {StakedEther} from "./StakedEther.sol";

contract StakingApp is Ownable, Pausable {
    using SafeERC20 for IERC20;

    struct UnstakeRequest {
        uint256 amount;
        uint256 unlockTime;
    }

    StakedEther public stkEther;
    address public rewardToken;

    uint256 public rewardsRate;
    uint256 public unstakeDelay = 7 days;
    
    uint256 public totalStaked;

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public userRewards;

    mapping(address => uint256) public nextRequestId;
    mapping(address => mapping(uint256 => UnstakeRequest)) public unstakeRequests;


    event Staked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event UnstakeRequested(address indexed user, uint256 indexed requestId, uint256 amount, uint256 unlockTime);
    event UnstakeClaimed(address indexed user, uint256 indexed requestId, uint256 amount);

    error InvalidAddress();
    error ZeroAmount();
    error TooMuchTime();
    error EtherTransferFailed();
    error UnstakeStillLocked();
    error NoPendingUnstake();

    modifier updateReward(address _user) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (_user != address(0)) {
            userRewards[_user] = earned(_user);
            userRewardPerTokenPaid[_user] = rewardPerTokenStored;
        }
        _;
    }

    constructor(address _rewardToken, uint256 _rewardsRate) Ownable(msg.sender) {
        if (_rewardToken == address(0)) revert InvalidAddress();
        stkEther = new StakedEther();
        rewardToken = _rewardToken;
        rewardsRate = _rewardsRate;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;

        uint256 _elapsedTime = block.timestamp - lastUpdateTime;

        uint256 _increase = (rewardsRate * _elapsedTime * 1e18) / totalStaked;

        return rewardPerTokenStored + _increase;
    }

    function earned(address _user) public view returns (uint256) {
        uint256 _balance = stkEther.balanceOf(_user);

        uint256 _lastPhoto = rewardPerToken() - userRewardPerTokenPaid[_user];

        uint256 _newRewards = (_balance * _lastPhoto) / 1e18;

        return userRewards[_user] + _newRewards;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setRewardToken(address _token) external onlyOwner {
        if (_token == address(0)) revert InvalidAddress();
        rewardToken = _token;
    }

    function setRewardsRate(uint256 _rate) external onlyOwner updateReward(address(0)) {
        rewardsRate = _rate;
    }

    function setUnstakeDelay(uint256 _newDelay) external onlyOwner {
        if (_newDelay == 0) revert ZeroAmount();
        if (_newDelay > 30 days) revert TooMuchTime();
        unstakeDelay = _newDelay;
    }

    function stake() external payable whenNotPaused updateReward(msg.sender) {
        if (msg.value == 0) revert ZeroAmount();
        totalStaked += msg.value;
        stkEther.mint(msg.sender, msg.value);

        emit Staked(msg.sender, msg.value);
    }

    function requestUnstake(uint256 _amount) external whenNotPaused updateReward(msg.sender) {
        if (_amount == 0) revert ZeroAmount();

        stkEther.burn(msg.sender, _amount);

        totalStaked -= _amount;

        uint256 _requestId = nextRequestId[msg.sender];
        uint256 _unlockTime = block.timestamp + unstakeDelay;
        unstakeRequests[msg.sender][_requestId] = UnstakeRequest({amount: _amount, unlockTime: _unlockTime});

        nextRequestId[msg.sender]++;

        emit UnstakeRequested(msg.sender, _requestId, _amount, _unlockTime);
    }

    function claimUnstake(uint256 _requestId) external whenNotPaused {
        UnstakeRequest memory _unstakeRequest = unstakeRequests[msg.sender][_requestId];
        if (_unstakeRequest.amount == 0) revert NoPendingUnstake();
        if (block.timestamp < _unstakeRequest.unlockTime) revert UnstakeStillLocked();

        delete unstakeRequests[msg.sender][_requestId];

        (bool success,) = msg.sender.call{value: _unstakeRequest.amount}("");
        if (!success) revert EtherTransferFailed();

        emit UnstakeClaimed(msg.sender, _requestId, _unstakeRequest.amount);
    }

    function claimRewards() external whenNotPaused updateReward(msg.sender) {
        uint256 _userRewards = userRewards[msg.sender];
        if (_userRewards == 0) revert ZeroAmount();

        delete userRewards[msg.sender];
        IERC20(rewardToken).safeTransfer(msg.sender, _userRewards);

        emit RewardsClaimed(msg.sender, _userRewards);
    }
}