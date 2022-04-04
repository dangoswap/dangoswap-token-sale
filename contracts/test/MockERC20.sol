// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supply
    ) ERC20(tokenName, tokenSymbol) {
        _mint(msg.sender, supply);
    }
}
