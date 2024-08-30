// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../src/IERC20.sol";
import {MyERC20} from "../src/MyERC20.sol";
import {TokenReceiver} from "../src/TokenReceiver.sol";

contract TokenReceiverTest is Test {
    TokenReceiver public tokenReceiver;
    MyERC20 public myToken;
    address public user = address(1);

    function setUp() public {
        tokenReceiver = new TokenReceiver();
        myToken = new MyERC20("Test Token", "TST", 18);
        
        // Transfer some tokens to the user for testing
        myToken.transfer(user, 1000 * 10**18);
    }

    function testReceiveTokens() public {
        uint256 amount = 100 * 10**18;
        
        vm.startPrank(user);
        myToken.approve(address(tokenReceiver), amount);
        
        vm.expectEmit(true, true, false, true);
        emit TokenReceiver.TokensReceived(user, amount);
        
        tokenReceiver.receiveTokens(IERC20(address(myToken)), amount);
        vm.stopPrank();

        assertEq(myToken.balanceOf(address(tokenReceiver)), amount, "TokenReceiver balance should match transferred amount");
        assertEq(tokenReceiver.getBalance(IERC20(address(myToken))), amount, "getBalance should return correct amount");
    }
}