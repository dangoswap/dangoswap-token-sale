// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenPair.sol";

struct TokenPair {
      // token price for ETH
    uint256 tokensOutPerInNumerator;
    uint256 tokensOutPerInDenominator;
    ERC20 tokenIn;
    ERC20 tokenOut;
    address tokenInRecipient;
}

contract MasterTokenVendor is Ownable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    ERC20 public immutable weth;
    address public defaultTokenInRecipient;
    
    mapping (uint64 => TokenPair) pairs;
    uint64 public lastPairId;

    // can be used to lookup in/out token pair
    mapping (address => mapping(address => uint64)) pairLookup;

    event SwapTokens(
        uint64 indexed pairId,
        address indexed _from,
        address indexed _to,
        uint256 tokenInAmount,
        uint256 tokenOutAmount
    );

    constructor(
        ERC20 _weth,        
        address _defaultTokenInRecipient
    ) {
        require(address(_weth) != address(0));        
        require(_defaultTokenInRecipient != address(0));
        weth = _weth;
        defaultTokenInRecipient = _defaultTokenInRecipient;
    }

    function createPair(
        ERC20 _tokenIn,
        ERC20 _tokenOut,        
        uint256 _tokensOutPerInNumerator,
        uint256 _tokensOutPerInDenominator,
        address _tokenInRecipient) public returns (uint64) {
        require(address(_tokenIn) != address(0));
        require(address(_tokenOut) != address(0));
        require(
            _tokensOutPerInNumerator > 0,
            "_tokensOutPerInNumerator must be positive"
        );
        require(
            _tokensOutPerInDenominator > 0,
            "_tokensOutPerInDenominator must be positive"
        );
        TokenPair memory pair = TokenPair({
            tokensOutPerInNumerator: _tokensOutPerInNumerator,
            tokensOutPerInDenominator: _tokensOutPerInDenominator,
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            tokenInRecipient: _tokenInRecipient
        });

        pairs[++lastPairId] = pair;
        return lastPairId;
    }

    function setPrice(
        uint64 pairId,
        uint256 _tokensOutPerInNumerator,
        uint256 _tokensOutPerInDenominator
    ) public onlyOwner {

        TokenPair storage pair = pairs[pairId];
        require(address(pair.tokenIn) != address(0), "Token pair id not found");

        require(
            _tokensOutPerInNumerator > 0,
            "_tokensOutPerInNumerator must be positive"
        );
        require(
            _tokensOutPerInDenominator > 0,
            "_tokensOutPerInDenominator must be positive"
        );
        pair.tokensOutPerInNumerator = _tokensOutPerInNumerator;
        pair.tokensOutPerInDenominator = _tokensOutPerInDenominator;
    }

    
    function swapTokens(
        uint64 pairId,
        uint256 tokenInAmount,
        address from,
        address to
    ) public returns (uint256 tokenOutAmount) {
        TokenPair memory pair = pairs[pairId];
        require(address(pair.tokenIn) != address(0), "Token pair id not found");
        uint256 amountToBuy = tokenInAmount * pair.tokensOutPerInNumerator / pair.tokensOutPerInDenominator;

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = pair.tokenOut.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "There is not enough tokens to swap out"
        );

        address tokenInRecipient = pair.tokenInRecipient;
        if (tokenInRecipient == address(0)) tokenInRecipient = defaultTokenInRecipient;

        bool received = pair.tokenIn.transferFrom(
            from,
            tokenInRecipient,
            tokenInAmount
        );
        require(received, "Failed to receive token from user");

        // Transfer token to the msg.sender
        bool sent = pair.tokenOut.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit SwapTokens(pairId, from, to, tokenInAmount, amountToBuy);

        return amountToBuy;
    }

    function getPair(uint64 pairId) public view returns (TokenPair memory pair) {
        pair = pairs[pairId];
        require(address(pair.tokenIn) != address(0), "Token pair id not found");
    }
}