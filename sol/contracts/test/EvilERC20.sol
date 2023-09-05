//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "../GenericERC20.sol";

contract EvilERC20 is GenericERC20 {
    constructor(string memory tokenName, string memory tokenSymbol) GenericERC20(tokenName, tokenSymbol) {}

    function transfer(address, uint256) public virtual override returns (bool) {
        return false;
    }
}
