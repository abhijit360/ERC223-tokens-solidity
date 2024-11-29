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
     // Return the current balance of ethereum held by this contract
    function ethBalance() view external returns (uint)
    {
        return address(this).balance;
    }
    
    // Return the quantity of tokens held by this contract
    function tokenBalance() virtual external view returns(uint){
        return balances[this.address]; // uses the balances array of the IERC2223 interface
    };

    // indicate that this contract has tokens for sale at some price, so buyFromMe will be successful
    function putUpForSale(uint amt, uint price) virtual public
    {
        return amt.mul(price);
    }
 
    // This function is called by the buyer to pay in ETH and receive tokens.  Note that this contract should ONLY sell the amount of tokens at the price specified by putUpForSale!
    function sellToCaller(address to, uint qty) virtual external payable
    {
        require(msg.sender == to); // only address buying can call this
        require(qty < amtForSale); // check if the qty of purchase is less than amount available for sale
        require(qty <= balances[address(this)]); // check if contract has enough tokens
        require(msg.value == putUpForSale(qty,pricePer));// check that the amount paid for each token is correct
        balances[msg.sender].add(qty); // transfer token to address
        balances[this.address].sub(qty)
    }
   
  
    // buy tokens from another holder.  This is OPTIONALLY payable.  The caller can provide the purchase ETH, or expect that the contract already holds it.
    function buy(uint amt, uint maxPricePer, TokenHolder seller) virtual public payable onlyOwner
    {
        // onlyOwner handles the case that only the owner of the transactionc an call this
        require(seller.tokenBalance() >= amt); // attest to see if the seller has enough tokens to sell
        require(msg.value >= amt.mul(maxPricePer)); // check to see if the buyer has sent enough money to make this transaction
        
        // handle token exchange
        balances[address(seller)].add(amt); // add the tokens to the seller's balance
        balances[msg.sender].sub(amt); // subtract the tokens from the buyer's balance
        
        // handle ETH exchange
        address payable sellerAddresses = payable(seller.address);
        sellerAddresses.transfer(amt.mul(maxPricePer)); // transfer the money to the seller
    }
    
    // Owner can send tokens
    function withdraw(address to, uint amount) virtual public onlyOwner
    {
        require(balances[msg.sender] >= amount); // check if the owner has enough tokens to withdraw
        balances[to].add(amount);
        balances[msg.sender].sub(amount);
    }

    // Sell my tokens back to the token manager
    function remit(uint amt, uint _pricePer, TokenManager mgr) virtual public onlyOwner payable
    {
        require(mgr.ethBalance() >= amt.mul(_pricePer)); // check if the manager has enough money to buy the tokens
        require(balances[msg.sender] >= amt); // check if the owner has enough tokens to sell
        mgr.buy(amt, _pricePer, msg.sender);
    }
    
    // Validate that this contract can handle tokens of this type
    // You need to define this function in your derived classes, but it is already specified in IERC223Recipient
    //function tokenFallback(address _from, uint /*_value*/, bytes memory /*_data*/) override external
}


contract TokenManager is ERC223Token, TokenHolder
{
    // Implement all functions
    
    // Pass the price per token (the specified exchange rate), and the fee per token to
    // set up the manager's buy/sell activity
    constructor(uint _price, uint _fee) TokenHolder(this) payable
    {
        pricePerToken = _price;
        feePerTransaction = _fee;
    }
    
    // Returns the total price for the passed quantity of tokens
    function price(uint amt) public view returns(uint) 
    {  
        return this.pricePerToken * amt;
    }

    // Returns the total fee, given this quantity of tokens
    function fee(uint amt) public view returns(uint) 
    {  
        return this.feePerTransaction * amt;
    }
    
    // Caller buys tokens from this contract
    function sellToCaller(address to, uint amount) payable override public
    {
        require(balances[this] >= amount);
        require(this.balance >= amount * pricePerToken);
        
    }
    
    // Caller sells tokens to this contract
    function buyFromCaller(uint amount) public payable
    {   
        requre(balances[msg.sender] >= amount);
        balances[this.address].add(amount);

        address payable callerAddress = payable(msg.address)
        callerAddress.transfer(amount * this.pricePerToken);
    }
    
    
    // Create some new tokens, and give them to this TokenManager
    function mint(uint amount) internal onlyOwner
    {
        balances[this.address].add(amount);
    }
    
    // Destroy some existing tokens, that are owned by this TokenManager
    function melt(uint amount) external onlyOwner
    {
        balances[this.address].sub(amount);
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



