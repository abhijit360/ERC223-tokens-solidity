// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
      require(msg.sender == owner, "Only owner can call this function.");
      _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}
