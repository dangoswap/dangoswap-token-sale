// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVendor is Ownable {    

    // token price for ETH
    uint256 public tokensOutPerInNumerator;
    uint256 public tokensOutPerInDenominator;
    ERC20 public immutable tokenIn;
    ERC20 public immutable tokenOut;
    ERC20 public immutable weth;
    address public tokenInRecipient;

    event SwapTokens(        
        address indexed _to,
        uint256 _tokenInAmount,
        uint256 _tokenOutAmount
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
        uint256 _tokenInAmount
    ) public returns (uint256 _tokenOutAmount) {
        address to = msg.sender;
        address from = msg.sender;

        uint256 amountToBuy = _tokenInAmount * tokensOutPerInNumerator / tokensOutPerInDenominator;

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = tokenOut.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "There is not enough tokens to swap out"
        );

        bool received = tokenIn.transferFrom(
            from,
            tokenInRecipient,
            _tokenInAmount
        );
        require(received, "Failed to receive token from user");

        // Transfer token to the msg.sender
        bool sent = tokenOut.transfer(to, amountToBuy);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit SwapTokens(to, _tokenInAmount, amountToBuy);

        return amountToBuy;
    }

    function withdrawToken(address _tokenRecipient, uint256 _amount) public onlyOwner {
        require(_amount > 0);
        require(_tokenRecipient != address(0));
        bool sent = tokenOut.transfer(_tokenRecipient, _amount);
        require(sent, "Failed to transfer token to recipient");        
        emit SwapTokens(_tokenRecipient, 0, _amount);
    }
}
