// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {OddNiBank} from "../src/OddNiBank.sol";


contract LoanBorrower {
    OddNiBank public bank;

    constructor(address payable _bank) {
        bank = OddNiBank(_bank);
    }

    receive() external payable {
        (bool success, ) = address(bank).call{value: msg.value}("");
        require(success, "Return Ether failed");
    }

    function executeFlashloan(uint256 _amount) external {
        bank.flashloan(_amount);
    }

}
