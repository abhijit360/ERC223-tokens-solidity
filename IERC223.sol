// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * [ERC1820 registry standard](https://eips.ethereum.org/EIPS/eip-1820) to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See `IERC1820Registry` and
 * `ERC1820Implementer`.
 *
 * https://github.com/ethereum/eips/issues/223
 */

abstract contract IERC223 {
    /**
     * @dev Returns the total supply of the token.
     */
    uint public _totalSupply;
    
    /**
     * @dev Returns the balance of the `who` address.
     */
    function balanceOf(address who) virtual external view returns (uint);
        
    /**
     * @dev Transfers `value` tokens from `msg.sender` to `to` address
     * and returns `true` on success.
     */
    function transfer(address to, uint value) virtual external returns (bool success);
        
    /**
     * @dev Transfers `value` tokens from `msg.sender` to `to` address with `data` parameter
     * and returns `true` on success.
     */
    function transfer(address to, uint value, bytes calldata data) virtual external returns (bool success);
     
     /**
     * @dev Event that is fired on successful transfer.
     */
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


/**
 * @title Contract that will work with ERC223 tokens.
 */
abstract contract IERC223Recipient { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes calldata _data) virtual external;
}
