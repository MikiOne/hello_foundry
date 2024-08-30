// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./ERC20.sol";

contract TokenReceiver {
    event TokensReceived(address from, uint256 amount);

    function receiveTokens(IERC20 token, uint256 amount) external {
        // 调用ERC20合约的transfer方法
        require(token.transfer(address(this), amount), "Transfer failed");

        // 触发TokensReceived事件
        emit TokensReceived(msg.sender, amount);
    }

    function getBalance(IERC20 token) external view returns (uint256) {
        // 查询当前合约的ERC20余额
        return token.balanceOf(address(this));
    }
}
