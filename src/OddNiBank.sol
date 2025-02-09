// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract OddNiBank{
    // The Contract will have some constants
    uint256 public constant BONUS_TO_PAY = 1 ether;

    // Security Meassure
    // reentrancyLock - This method will lock every function in this contract upon withdrawal, ensures that 
    //                  No Reentrancy is possible to drain the contract, or access to any crucial function
    //                  within this contract.
    bool public reentrancyLock;
    
    // The Contract will have some mappings:
    // assetInvested - Asset that are currently deposited to the bank
    // bonusTaken - Map if member already taken bonus
    // members - If an address is a member of the bank  
    mapping (address => uint256) public assetInvested;
    mapping (address => bool) public bonusTaken;
    mapping (address => bool) public isMember;

    // Custom Errors
    error NotEligibleForBonus();
    error AlreadyRegistered();
    error NotMember();
    error ContractLocked();
    
    modifier onlyMember {
        if (!isMember[msg.sender]) {
            revert NotMember();
        }
        _;
    }

    modifier guardActive(){
        if(reentrancyLock == true){
            revert ContractLocked();
        }
        _;
    }

    constructor() payable {
        reentrancyLock = false;
    }

    function registerAsMember() public guardActive{
        if ( isMember[msg.sender] ){
            revert AlreadyRegistered();
        }
        isMember[msg.sender] = true;
    }

    // @audit-high01 claimRegistrationBonus actually send BONUS_TO_PAY ether to the caller and also update the assetInvested mapping, makes user effectively have 2 rewards instead of intended 1
    function claimRegistrationBonus() public onlyMember guardActive{
        if (bonusTaken[msg.sender]) {
            revert NotEligibleForBonus();
        }
        bonusTaken[msg.sender] = true;
        assetInvested[msg.sender] += BONUS_TO_PAY;
        reentrancyLock = true;
        (bool sent, ) = msg.sender.call{value: BONUS_TO_PAY}("");
        require(sent, "Failed to claim bonus!");
        reentrancyLock = false;
    }

    function depositAsset() public payable onlyMember guardActive{
        require(msg.value > 0, "Deposit must be greater than zero.");
        uint256 _toAdd = msg.value;
        assetInvested[msg.sender] += _toAdd;
    }

    function withdrawAsset(uint256 _amount) public onlyMember guardActive{
        require(_amount > 0, "Withdrawal must be greater than zero.");
        require(assetInvested[msg.sender] - _amount >= 0, "Not enough balance in account!");
        // Prepare some variables
        uint256 _toWithdraw = _amount;
        uint256 newBalance = assetInvested[msg.sender] - _toWithdraw;
        uint256 previousBalance = address(this).balance;
        // Activate the Guard to prevent reentrancy
        reentrancyLock = true;
        // Sending the Balance
        (bool sent, ) = msg.sender.call{value: _toWithdraw}("");
        require(sent, "Withdrawal Failed!");
        // Upon Success Deactivate the Lock
        reentrancyLock = false;
        uint256 postWithdrawBalance = address(this).balance +  _toWithdraw;
        require(postWithdrawBalance == previousBalance, "Balance doesn't match!");
        assetInvested[msg.sender] = newBalance;
    }

    // Bank also has a "Loan"-model
    function flashloan(uint256 _amount) public onlyMember{
        require(address(this).balance >= _amount, "Owner has insufficient funds");
        uint256 balanceBefore = address(this).balance;
        //Do the flash loan
        reentrancyLock = true;
        (bool loaned, ) = msg.sender.call{value: _amount}("");
        require(loaned, "Flash Loan failed");
        reentrancyLock = false;
        require(address(this).balance == balanceBefore, "Flash loan failed"); 
    }

    // Getter function for the OddniBenefit.sol
    function getMemberStatus(address _account) public view returns(bool){
        return isMember[_account];
    }

    function getDepositedAmount(address _account) public view returns(uint256){
        return assetInvested[_account];
    }

    // The receive() ensures that the external call directly to the contract won't cause
    // lost of funds. It will check whether the sender is already a member or else, it 
    // will just dismiss the transaction. Else add the baalnce to the sender account.
    receive() external payable{
        if (!isMember[msg.sender]) {
            revert NotMember();
        }
        // @audit-high02 when paying flashloan, the contract will add the amount to assetInvested, wrongly update the user invested balance
        assetInvested[msg.sender] += msg.value;
    }

}
