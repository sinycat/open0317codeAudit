// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "../src/MyToken.sol";

contract TokenBankTest is Test {
    TokenBank public bank;
    MyToken public token;
    
    address public alice = address(0x1);
    address public bob = address(0x2);
    uint256 public constant INITIAL_BALANCE = 10 ether;
    uint256 public constant TOKEN_AMOUNT = 1000 * 10**18; // 1000 tokens
    
    function setUp() public {
        // 部署合约
        bank = new TokenBank();
        token = new MyToken();
        
        // 给测试账户一些ETH
        vm.deal(alice, INITIAL_BALANCE);
        vm.deal(bob, INITIAL_BALANCE);
        
        // 给测试账户一些代币
        vm.startPrank(address(this));
        token.transfer(alice, TOKEN_AMOUNT);
        token.transfer(bob, TOKEN_AMOUNT);
        vm.stopPrank();
    }
    
    // 测试ETH存款
    function testDepositETH() public {
        uint256 depositAmount = 1 ether;
        
        vm.startPrank(alice);
        bank.depositETH{value: depositAmount}();
        vm.stopPrank();
        
        assertEq(bank.getEthBalance(alice), depositAmount, "ETH deposit failed");
        assertEq(address(bank).balance, depositAmount, "Bank balance incorrect");
    }
    
    // 测试ETH取款
    function testWithdrawETH() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 0.5 ether;
        
        // 先存款
        vm.startPrank(alice);
        bank.depositETH{value: depositAmount}();
        
        uint256 balanceBefore = alice.balance;
        bank.withdrawETH(withdrawAmount);
        uint256 balanceAfter = alice.balance;
        vm.stopPrank();
        
        assertEq(balanceAfter - balanceBefore, withdrawAmount, "ETH withdrawal amount incorrect");
        assertEq(bank.getEthBalance(alice), depositAmount - withdrawAmount, "Remaining ETH balance incorrect");
    }
    
    // 测试ETH取款失败（余额不足）
    function testFailWithdrawETHInsufficientBalance() public {
        uint256 depositAmount = 0.5 ether;
        uint256 withdrawAmount = 1 ether;
        
        vm.startPrank(alice);
        bank.depositETH{value: depositAmount}();
        bank.withdrawETH(withdrawAmount); // 应该失败
        vm.stopPrank();
    }
    
    // 测试代币存款
    function testDepositToken() public {
        uint256 depositAmount = 100 * 10**18; // 100 tokens
        
        vm.startPrank(alice);
        token.approve(address(bank), depositAmount);
        bank.depositToken(address(token), depositAmount);
        vm.stopPrank();
        
        assertEq(bank.getTokenBalance(alice, address(token)), depositAmount, "Token deposit failed");
        assertEq(token.balanceOf(address(bank)), depositAmount, "Bank token balance incorrect");
    }
    
    // 测试代币取款
    function testWithdrawToken() public {
        uint256 depositAmount = 100 * 10**18; // 100 tokens
        uint256 withdrawAmount = 50 * 10**18; // 50 tokens
        
        // 先存款
        vm.startPrank(alice);
        token.approve(address(bank), depositAmount);
        bank.depositToken(address(token), depositAmount);
        
        uint256 balanceBefore = token.balanceOf(alice);
        bank.withdrawToken(address(token), withdrawAmount);
        uint256 balanceAfter = token.balanceOf(alice);
        vm.stopPrank();
        
        assertEq(balanceAfter - balanceBefore, withdrawAmount, "Token withdrawal amount incorrect");
        assertEq(bank.getTokenBalance(alice, address(token)), depositAmount - withdrawAmount, "Remaining token balance incorrect");
    }
    
    // 测试代币取款失败（余额不足）
    function testFailWithdrawTokenInsufficientBalance() public {
        uint256 depositAmount = 50 * 10**18; // 50 tokens
        uint256 withdrawAmount = 100 * 10**18; // 100 tokens
        
        vm.startPrank(alice);
        token.approve(address(bank), depositAmount);
        bank.depositToken(address(token), depositAmount);
        bank.withdrawToken(address(token), withdrawAmount); // 应该失败
        vm.stopPrank();
    }
    
    // 测试receive函数（直接发送ETH到合约）
    function testReceiveFunction() public {
        uint256 sendAmount = 1 ether;
        
        vm.startPrank(alice);
        (bool success, ) = address(bank).call{value: sendAmount}("");
        require(success, "ETH transfer failed");
        vm.stopPrank();
        
        assertEq(bank.getEthBalance(alice), sendAmount, "ETH receive failed");
        assertEq(address(bank).balance, sendAmount, "Bank balance incorrect");
    }
    
    // 测试多用户操作
    function testMultipleUsers() public {
        // Alice存入ETH
        vm.prank(alice);
        bank.depositETH{value: 1 ether}();
        
        // Bob存入代币
        vm.startPrank(bob);
        token.approve(address(bank), 100 * 10**18);
        bank.depositToken(address(token), 100 * 10**18);
        vm.stopPrank();
        
        assertEq(bank.getEthBalance(alice), 1 ether, "Alice's ETH balance incorrect");
        assertEq(bank.getEthBalance(bob), 0, "Bob's ETH balance incorrect");
        assertEq(bank.getTokenBalance(alice, address(token)), 0, "Alice's token balance incorrect");
        assertEq(bank.getTokenBalance(bob, address(token)), 100 * 10**18, "Bob's token balance incorrect");
    }
} 