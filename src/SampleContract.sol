// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// write a smart contract that implements a Multisig wallet

contract SampleContract {
    uint256 public num;

    constructor() {
        num = 0;
    }

    function setNum(uint256 _num) external payable {
        require(_num != 0, "Nope");
        num = _num;
    }

    fallback() external payable {}
}
