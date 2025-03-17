// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface AutomationCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract TokenBank is ReentrancyGuard, AutomationCompatibleInterface {
    using SafeERC20 for IERC20;
    
    // Record user deposit balances
    mapping(address => uint256) private ethBalances;
    mapping(address => mapping(address => uint256)) private tokenBalances;
    
    // Events
    event EthDeposited(address indexed user, uint256 amount);
    event EthWithdrawn(address indexed user, uint256 amount);
    event TokenDeposited(address indexed user, address indexed token, uint256 amount);
    event TokenWithdrawn(address indexed user, address indexed token, uint256 amount);
    
    // Deposit ETH
    function depositETH() external payable {
        require(msg.value > 0, "Must deposit ETH");
        ethBalances[msg.sender] += msg.value;
        emit EthDeposited(msg.sender, msg.value);
    }
    
    // Withdraw ETH
    function withdrawETH(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(ethBalances[msg.sender] >= amount, "Insufficient ETH balance");
        
        ethBalances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
        
        emit EthWithdrawn(msg.sender, amount);
    }
    
    // Deposit ERC20 token
    function depositToken(address token, uint256 amount) external {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Deposit amount must be greater than 0");
        
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        tokenBalances[msg.sender][token] += amount;
        
        emit TokenDeposited(msg.sender, token, amount);
    }
    
    // Withdraw ERC20 token
    function withdrawToken(address token, uint256 amount) external nonReentrant {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(tokenBalances[msg.sender][token] >= amount, "Insufficient token balance");
        
        tokenBalances[msg.sender][token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        
        emit TokenWithdrawn(msg.sender, token, amount);
    }
    
    // Query ETH balance
    function getEthBalance(address user) external view returns (uint256) {
        return ethBalances[user];
    }
    
    // Query token balance
    function getTokenBalance(address user, address token) external view returns (uint256) {
        return tokenBalances[user][token];
    }
    
    // Fallback function to receive ETH
    receive() external payable {
        ethBalances[msg.sender] += msg.value;
        emit EthDeposited(msg.sender, msg.value);
    }


    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        if (address(this).balance > 0) {
             upkeepNeeded = true;
        }
        performData = checkData;
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external {
        address account = abi.decode(performData, (address));
        if (address(this).balance > 0) {
            payable(account).transfer(address(this).balance);
        }
    }
}
