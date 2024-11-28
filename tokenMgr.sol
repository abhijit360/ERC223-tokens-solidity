// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IERC223.sol";
import "./ERC223.sol";
import "./ownable.sol";

abstract contract ITokenHolder is IERC223Recipient, Ownable
{
    IERC223 public currency;
    uint256 public pricePer;  // In wei
    uint256 public amtForSale;

    // Return the current balance of ethereum held by this contract
    function ethBalance() view external returns (uint)
    {
        return address(this).balance;
    }
    
    // Return the quantity of tokens held by this contract
    function tokenBalance() virtual external view returns(uint);

    // indicate that this contract has tokens for sale at some price, so buyFromMe will be successful
    function putUpForSale(uint /*amt*/, uint /*price*/) virtual public
    {
        assert(false);
    }
 
    // This function is called by the buyer to pay in ETH and receive tokens.  Note that this contract should ONLY sell the amount of tokens at the price specified by putUpForSale!
    function sellToCaller(address /*to*/, uint /*qty*/) virtual external payable
    {
        assert(false);
    }
   
  
    // buy tokens from another holder.  This is OPTIONALLY payable.  The caller can provide the purchase ETH, or expect that the contract already holds it.
    function buy(uint /*amt*/, uint /*maxPricePer*/, TokenHolder /*seller*/) virtual public payable onlyOwner
    {
        assert(false);
    }
    
    // Owner can send tokens
    function withdraw(address /*_to*/, uint /*amount*/) virtual public onlyOwner
    {
        assert(false);
    }

    // Sell my tokens back to the token manager
    function remit(uint /*amt*/, uint /*_pricePer*/, TokenManager /*mgr*/) virtual public onlyOwner payable
    {
        assert(false);
    }
    
    // Validate that this contract can handle tokens of this type
    // You need to define this function in your derived classes, but it is already specified in IERC223Recipient
    //function tokenFallback(address _from, uint /*_value*/, bytes memory /*_data*/) override external

}

contract TokenHolder is ITokenHolder
{
    constructor(IERC223 _cur)
    {
        currency = _cur;
    }
    
    // Implement all ITokenHolder functions and tokenFallback
}


contract TokenManager is ERC223Token, TokenHolder
{
    // Implement all functions
    
    // Pass the price per token (the specified exchange rate), and the fee per token to
    // set up the manager's buy/sell activity
    constructor(uint _price, uint _fee) TokenHolder(this) payable
    {
    }
    
    // Returns the total price for the passed quantity of tokens
    function price(uint amt) public view returns(uint) 
    {  
        
    }

    // Returns the total fee, given this quantity of tokens
    function fee(uint amt) public view returns(uint) 
    {  
        
    }
    
    // Caller buys tokens from this contract
    function sellToCaller(address to, uint amount) payable override public
    {
    }
    
    // Caller sells tokens to this contract
    function buyFromCaller(uint amount) public payable
    {
    }
    
    
    // Create some new tokens, and give them to this TokenManager
    function mint(uint amount) internal onlyOwner
    {
    }
    
    // Destroy some existing tokens, that are owned by this TokenManager
    function melt(uint amount) external onlyOwner
    {
    }
}


contract AATest
{
    event Log(string info);

    function TestBuyRemit() payable public returns (uint)
    {
        emit Log("trying TestBuyRemit");
        TokenManager tok1 = new TokenManager(100,1);
        TokenHolder h1 = new TokenHolder(tok1);

        uint amt = 2;
        tok1.sellToCaller{value:tok1.price(amt) + tok1.fee(amt)}(address(h1),amt);
        assert(tok1.balanceOf(address(h1)) == amt);

        h1.remit{value:tok1.fee(amt)}(1,50,tok1);
        assert(tok1.balanceOf(address(h1)) == 1);
        assert(tok1.balanceOf(address(tok1)) == 1);
        
        return tok1.price(1);
    } 
    
    function FailBuyBadFee() payable public
    {
        TokenManager tok1 = new TokenManager(100,1);
        TokenHolder h1 = new TokenHolder(tok1);

        uint amt = 2;
        tok1.sellToCaller{value:1}(address(h1),amt);
        assert(tok1.balanceOf(address(h1)) == 2);
    }
    
   function FailRemitBadFee() payable public
    {
        TokenManager tok1 = new TokenManager(100,1);
        TokenHolder h1 = new TokenHolder(tok1);

        uint amt = 2;
        tok1.sellToCaller{value:tok1.price(amt) + tok1.fee(amt)}(address(h1),amt);
        assert(tok1.balanceOf(address(h1)) == amt);
        emit Log("buy complete");
        
        h1.remit{value:tok1.fee(amt-1)}(2,50,tok1);
    } 
      
    function TestHolderTransfer() payable public
    {
        TokenManager tok1 = new TokenManager(100,1);
        TokenHolder h1 = new TokenHolder(tok1);
        TokenHolder h2 = new TokenHolder(tok1);
        
        uint amt = 2;
        tok1.sellToCaller{value:tok1.price(amt) + tok1.fee(amt)}(address(h1),amt);
        assert(tok1.balanceOf(address(h1)) == amt);
        
        h1.putUpForSale(2, 200);
        h2.buy{value:2*202}(1,202,h1);
        h2.buy(1,202,h1);  // Since I loaded money the first time, its still there now.       
    }
    
}



