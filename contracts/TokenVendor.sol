// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenVendor {

    using SafeMath for uint256;

    // token price for ETH
    uint256 public tokensOutPerInNumerator = 12;
    uint256 public tokensOutPerInDenominator = 100;
    ERC20 public tokenIn;
    ERC20 public tokenOut;
    address public tokenInRecipient;

    event SwapTokens(address indexed _from, address indexed _to, uint tokenInAmount, uint tokenOutAmount);

    constructor(ERC20 _tokenIn, ERC20 _tokenOut) {
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
    }
    
    function swapTokens(uint256 tokenInAmount, address from, address to) public returns (uint256 tokenOutAmount) {
        uint256 amountToBuy = tokenInAmount
            .mul(tokensOutPerInNumerator)
            .div(tokensOutPerInDenominator);

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = tokenOut.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        bool received = tokenIn.transferFrom(from, tokenInRecipient, tokenInAmount);
        require(received, "Failed to receive token from user");

        // Transfer token to the msg.sender
        bool sent = tokenOut.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit SwapTokens(from, to, tokenInAmount, amountToBuy);

        return amountToBuy;
    }
}
