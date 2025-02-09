// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import "../src/OddNiBank.sol";
import "../src/OddNiBenefit.sol";
// import "../src/attek.sol";
import {Test, console} from "forge-std/Test.sol";
import {LoanBorrower} from "./LoanBorrower.sol";

contract OddNiOverallTest is Test {
    // account
    address public deployer = makeAddr("deployer");
    address public tester = makeAddr("tester");
    address public victim = makeAddr("victim");

    OddNiBank public OBA;
    OddNiBenefit public OBE;
    // atek public ATT;

    uint256 public constant MINIMUM_DEPOSIT = 5 ether;
    uint256 public constant MINIMUM_HOLD_DURATION = 30 days;
    uint256 public constant LOYALTY_REWARD = 0.1 ether;

    function setUp() public {
        vm.startPrank(deployer);
        vm.deal(deployer, 1000 ether);
        OBA = new OddNiBank{value: 500 ether}();
        OBE = new OddNiBenefit{value: 100 ether}(payable(address(OBA)));
        vm.stopPrank();
    }

    function testForAccessWithoutMember() public {
        // Attempt to call claimRegistrationBonus as a non-member
        vm.startPrank(tester);
        vm.expectRevert(OddNiBank.NotMember.selector);
        OBA.claimRegistrationBonus(); // This call should fail and revert with NotMember
        vm.stopPrank();

        // Deposit
        vm.startPrank(tester);
        vm.deal(tester, 100 ether);
        vm.expectRevert(OddNiBank.NotMember.selector);
        OBA.depositAsset{value: 10 ether}(); // This call should fail and revert with NotMember
        vm.stopPrank();

        // Other function are irrelevant for this test since they fall behind the condition of
        // the functions above is able to be accessed.
    }

    function testForMultipleRegistration() public {
        vm.startPrank(tester);
        OBA.registerAsMember();
        vm.expectRevert(OddNiBank.AlreadyRegistered.selector);
        OBA.registerAsMember(); // This call should fail and revert with AlreadyRegistered
        vm.stopPrank();
    }

    function testForDeposit() public {
        vm.startPrank(tester);
        vm.deal(tester, 100 ether);
        OBA.registerAsMember();
        OBA.depositAsset{value: 50 ether}();
        assertEq(OBA.getDepositedAmount(address(tester)), 50 ether);
    }

    function testForCustomReentrancyLock() public {
        // The internal Auditor has tested this function. TRUST ME.
    }

    function testForAccidentalETHSend() public {
        // Triggering the receive() function
        vm.startPrank(tester);
        vm.deal(tester, 100 ether);
        OBA.registerAsMember();
        (bool success, ) = payable(address(OBA)).call{value: 10 ether}("");
        require(success, "Failed to send ETH to the contract");
        vm.stopPrank();

        assertEq(OBA.getDepositedAmount(tester), 10 ether);
        console.log("Tester sent 10 ether directly to the contract.");
    }

    // Test for the royalty reward function in OddNiBenefit
    function testForRoyaltyReward() public {
        vm.startPrank(tester);
        vm.deal(tester, 10 ether);

        // Register as a member and deposit the minimum required amount
        OBA.registerAsMember();
        OBA.depositAsset{value: MINIMUM_DEPOSIT}();

        // Register the deposit timestamp in OddNiBenefit
        OBE.registerDeposit();

        // Fast forward time by 30 days to meet the holding period requirement
        vm.warp(block.timestamp + MINIMUM_HOLD_DURATION);

        // Capture the tester's initial balance
        uint256 initialBalance = tester.balance;

        // Claim the loyalty reward
        OBE.rewardLoyalMembers();

        // Verify the reward has been received
        uint256 finalBalance = tester.balance;
        assertEq(
            finalBalance,
            initialBalance + LOYALTY_REWARD,
            "Loyalty reward not received"
        );

        vm.stopPrank();
    }

    // Test royalty reward revert if holding period not met
    function testForRoyaltyReward_RevertIfHoldingPeriodNotMet() public {
        vm.startPrank(tester);
        vm.deal(tester, 10 ether);
        OBA.registerAsMember();
        OBA.depositAsset{value: MINIMUM_DEPOSIT}();
        OBE.registerDeposit();
        vm.expectRevert(bytes("Holding period not met"));
        OBE.rewardLoyalMembers();

        vm.stopPrank();
    }

    // Test royalty reward revert if caller is not a member
    function testForRoyaltyReward_RevertIfNotMember() public {
        vm.startPrank(tester);
        vm.deal(tester, 10 ether);
        vm.expectRevert(bytes("Not a member of OddNiBank"));
        OBE.registerDeposit();

        vm.stopPrank();
    }

    function test_PoC_bypassHoldingTimestamps() public {
        // first set the timestamp to current time. eg 4 jan 2025: 1735996788
        vm.warp(1735996788);

        vm.startPrank(tester);
        vm.deal(tester, 10 ether);

        OBA.registerAsMember();

        OBA.depositAsset{value: MINIMUM_DEPOSIT}();

        uint256 initialBalance = tester.balance;
        OBE.rewardLoyalMembers();
        uint256 finalBalance = tester.balance;

        // check if the reward is received by checking if finalBalance is greater than initialBalance
        assert(finalBalance > initialBalance);
        vm.stopPrank();
    }

    function testFlashloanByContractStateChangers() public {
        LoanBorrower loanBorrower = new LoanBorrower(payable(address(OBA)));
        vm.deal(address(loanBorrower), 10 ether);
        vm.prank(address(loanBorrower));
        OBA.registerAsMember();

        vm.prank(address(loanBorrower));
        OBA.depositAsset{value: 2 ether}();

        uint256 borrowerBalanceBefore = address(loanBorrower).balance;

        uint256 loanAmount = 1 ether;
        uint256 balanceBefore = address(OBA).balance;

        loanBorrower.executeFlashloan(loanAmount);
        uint256 balanceAfter = address(OBA).balance;
        assertEq(
            balanceBefore,
            balanceAfter,
            "Contract balance did not return to the original amount!"
        );

        bool lockState = OBA.reentrancyLock();
        assertEq(
            lockState,
            false,
            "Reentrancy lock Should be false after flashloan"
        );

        uint256 contractBankBalanceAfter = address(OBA).balance;
        assertEq(
            balanceBefore,
            contractBankBalanceAfter,
            "Contract Balance should match"
        );

        // make sure member balance not change
        uint256 memberBalanceAfter = address(loanBorrower).balance;
        assertEq(
            borrowerBalanceBefore,
            memberBalanceAfter,
            "Member balance should not change"
        );

        uint256 contractassetInvestedAfter = OBA.getDepositedAmount(
            address(loanBorrower)
        );
        assertEq(
            contractassetInvestedAfter,
            2 ether,
            "Asset Invested Should Remain Unchanged"
        );

        bool contractBonusStatus = OBA.bonusTaken(address(loanBorrower));
        assertEq(contractBonusStatus, false, "Bonus Should Remain Unchanged");
        bool ContractmemberStatus = OBA.getMemberStatus(address(loanBorrower));
        assertEq(
            ContractmemberStatus,
            true,
            "Member Status Should Remain unchanged"
        );
    }
}
