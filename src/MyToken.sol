// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MTK") {
        // 铸造100万代币给合约部署者（owner）
        // 注意：ERC20使用18位小数，所以需要乘以10^18
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    // 允许任何人铸造代币的公开函数
    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
