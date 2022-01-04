// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVendor is Ownable {
    using SafeMath for uint256;

    // token price for ETH
    uint256 public tokensOutPerInNumerator;
    uint256 public tokensOutPerInDenominator;
    ERC20 public immutable tokenIn;
    ERC20 public immutable tokenOut;
    ERC20 public immutable weth;
    address public tokenInRecipient;

    event SwapTokens(
        address indexed _from,
        address indexed _to,
        uint256 tokenInAmount,
        uint256 tokenOutAmount
    );

    constructor(
        ERC20 _weth,
        ERC20 _tokenIn,
        ERC20 _tokenOut,
        address _tokenInRecipient,
        uint256 _tokensOutPerInNumerator,
        uint256 _tokensOutPerInDenominator
    ) {
        require(address(_weth) != address(0));
        require(address(_tokenIn) != address(0));
        require(address(_tokenOut) != address(0));
        require(_tokenInRecipient != address(0));
        weth = _weth;
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;        
        tokenInRecipient = _tokenInRecipient;
        setPrice(_tokensOutPerInNumerator, _tokensOutPerInDenominator);
    }

    function setPrice(
        uint256 _tokensOutPerInNumerator,
        uint256 _tokensOutPerInDenominator
    ) public onlyOwner {
        require(
            _tokensOutPerInNumerator > 0,
            "_tokensOutPerInNumerator must be positive"
        );
        require(
            _tokensOutPerInDenominator > 0,
            "_tokensOutPerInDenominator must be positive"
        );
        tokensOutPerInNumerator = _tokensOutPerInNumerator;
        tokensOutPerInDenominator = _tokensOutPerInDenominator;
    }

    function swapTokens(
        uint256 tokenInAmount,
        address from,
        address to
    ) public returns (uint256 tokenOutAmount) {
        uint256 amountToBuy = tokenInAmount.mul(tokensOutPerInNumerator).div(
            tokensOutPerInDenominator
        );

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = tokenOut.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "There is not enough tokens to swap out"
        );

        bool received = tokenIn.transferFrom(
            from,
            tokenInRecipient,
            tokenInAmount
        );
        require(received, "Failed to receive token from user");

        // Transfer token to the msg.sender
        bool sent = tokenOut.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit SwapTokens(from, to, tokenInAmount, amountToBuy);

        return amountToBuy;
    }
}
