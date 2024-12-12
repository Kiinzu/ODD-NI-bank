// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./OddNiBank.sol";

contract OddNiBenefit {

    OddNiBank public OBE;
    uint256 public constant LOYALTY_REWARD = 0.1 ether;
    uint256 public constant MINIMUM_DEPOSIT = 5 ether;
    uint256 public constant MINIMUM_HOLD_DURATION = 30 days;


    mapping(address => uint256) public depositTimestamps;

    constructor(address payable _obe) payable {
        OBE = OddNiBank(_obe);
    }

    // Function for members to get a freebie from the bank!
    function memberFreebie() public{
        require(OBE.getMemberStatus(msg.sender), "Not a member of OddNiBank");
        require(OBE.getDepositedAmount(msg.sender) >= MINIMUM_DEPOSIT, "Deposit below minimum requirement");
        require(OBE.reentrancyLock() == false, "The Bank is currently under lockdown!");
        uint256 _toCalculate = OBE.getDepositedAmount(msg.sender);
        uint256 toGift = _toCalculate * 2;

        (bool sent, ) = msg.sender.call{value: toGift}("");
        require(sent, "Gift claim failed.");
    }

    // Function for members to register their deposit timestamp
    function registerDeposit() external {
        require(OBE.getMemberStatus(msg.sender), "Not a member of OddNiBank");
        require(OBE.getDepositedAmount(msg.sender) >= MINIMUM_DEPOSIT, "Deposit below minimum requirement");
        require(OBE.reentrancyLock() == false, "The Bank is currently under lockdown!");
        depositTimestamps[msg.sender] = block.timestamp;
    }

    // Reward loyal members who held the deposit for at least MINIMUM_HOLD_DURATION
    function rewardLoyalMembers() external {
        require(OBE.getMemberStatus(msg.sender), "Not a member of OddNiBank");
        require(block.timestamp >= depositTimestamps[msg.sender] + MINIMUM_HOLD_DURATION, "Holding period not met");
        require(address(this).balance >= LOYALTY_REWARD, "Insufficient contract balance");
        require(OBE.reentrancyLock() == false, "The Bank is currently under lockdown!");
        // Reset the timestamp before making the transfer to prevent reentrancy
        depositTimestamps[msg.sender] = block.timestamp;

        (bool sent, ) = msg.sender.call{value: LOYALTY_REWARD, gas: 2300}(""); // Limit gas to 2300
        require(sent, "Reward transfer failed");
    }

}
