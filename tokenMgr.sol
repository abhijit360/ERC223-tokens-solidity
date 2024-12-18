// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IERC223.sol";
import "./ERC223.sol";
import "./ownable.sol";

abstract contract ITokenHolder is IERC223Recipient, Ownable {
    IERC223 public currency;
    uint256 public pricePer; // In wei
    uint256 public amtForSale;

    // Return the current balance of ethereum held by this contract
    function ethBalance() external view returns (uint) {
        return address(this).balance;
    }

    // Return the quantity of tokens held by this contract
    function tokenBalance() external view virtual returns (uint);

    // indicate that this contract has tokens for sale at some price, so buyFromMe will be successful
    function putUpForSale(uint /*amt*/, uint /*price*/) public virtual {
        assert(false);
    }

    // This function is called by the buyer to pay in ETH and receive tokens.  Note that this contract should ONLY sell the amount of tokens at the price specified by putUpForSale!
    function sellToCaller(
        address /*to*/,
        uint /*qty*/
    ) external payable virtual {
        assert(false);
    }

    // buy tokens from another holder.  This is OPTIONALLY payable.  The caller can provide the purchase ETH, or expect that the contract already holds it.
    function buy(
        uint /*amt*/,
        uint /*maxPricePer*/,
        TokenHolder /*seller*/
    ) public payable virtual onlyOwner {
        assert(false);
    }

    // Owner can send tokens
    function withdraw(
        address /*_to*/,
        uint /*amount*/
    ) public virtual onlyOwner {
        assert(false);
    }

    // Sell my tokens back to the token manager
    function remit(
        uint /*amt*/,
        uint /*_pricePer*/,
        TokenManager /*mgr*/
    ) public payable virtual onlyOwner {
        assert(false);
    }

    // Validate that this contract can handle tokens of this type
    // You need to define this function in your derived classes, but it is already specified in IERC223Recipient
    //function tokenFallback(address _from, uint /*_value*/, bytes memory /*_data*/) override external
}

contract TokenHolder is ITokenHolder {
    constructor(IERC223 _cur) {
        currency = _cur;
    }

    // Implement all ITokenHolder functions and tokenFallback

    // Return the quantity of tokens held by this contract
    function tokenBalance() external view virtual override returns (uint) {
        return currency.balanceOf(address(this)); // uses the balances array of the IERC2223 interface
    }

    // indicate that this contract has tokens for sale at some price, so buyFromMe will be successful
    function putUpForSale(uint amt, uint price) public virtual override {
        require(amt > 0, "amt for sale must be more than");
        require(
            amt <= currency.balanceOf(address(this)),
            "you can't put up for sale what you don't have"
        ); // check if contract has enough tokens
        amtForSale = uint256(amt);
        pricePer = uint256(price);
    }

    // This function is called by the buyer to pay in ETH and receive tokens.  Note that this contract should ONLY sell the amount of tokens at the price specified by putUpForSale!
   function sellToCaller(address to, uint qty) external payable virtual override {
        require(qty > 0, "Quantity must be positive");
        require(qty <= amtForSale, "Exceeds amount for sale"); // Fixed comparison
        require(msg.value >= (qty * pricePer), "Incorrect payment amount");

        amtForSale -= qty; // Deduct sold quantity
        currency.transfer(to, qty); // Transfer tokens to buyer
    }

    

    // buy tokens from another holder.  This is OPTIONALLY payable.  The caller can provide the purchase ETH, or expect that the contract already holds it.
    function buy(
        uint amt,
        uint maxPricePer,
        TokenHolder seller
    ) public payable virtual override onlyOwner {
        // onlyOwner handles the case that only the owner of the transactionc an call this
        require(seller.tokenBalance() >= amt, "seller has insufficient funds"); // attest to see if the seller has enough tokens to sell
        require(seller.pricePer() <= maxPricePer, "we don't want to buy if the seller is selling at a maxPricePer. This could lead to an arbitrage situation.");
        require(this.ethBalance() >= (amt * seller.pricePer()), "ensure that the token holder has enough funds to buy the tokens");
        seller.sellToCaller{value: amt * seller.pricePer()}(address(this), amt);
    }

    // Owner can send tokens
    function withdraw(
        address to,
        uint amount
    ) public virtual override onlyOwner {
        // require(currency.balanceOf(address(this)) >= amount); // check if the owner has enough tokens to withdraw
        currency.transfer(to, amount);
    }

    // Sell my tokens back to the token manager
    function remit(
        uint amt,
        uint _pricePer,
        TokenManager mgr
    ) public payable virtual override onlyOwner {
        require(mgr.ethBalance() >= (amt * _pricePer)); // check if the manager has enough money to buy the tokens
        require(currency.balanceOf(address(this)) >= amt); // check if the owner has enough tokens to sell
        mgr.sellToCaller(address(this), amt);   
    }

    // Validate that this contract can handle tokens of this type
    // You need to define this function in your derived classes, but it is already specified in IERC223Recipient
    function tokenFallback(
        address _from,
        uint _value,
        bytes memory _data
    ) external override {}
}

contract TokenManager is ERC223Token, TokenHolder {
    // Implement all functions
    uint public pricePerToken;
    uint public feePerToken;
    // Pass the price per token (the specified exchange rate), and the fee per token to
    // set up the manager's buy/sell activity
    constructor(uint _price, uint _fee) payable TokenHolder(this) {
        pricePerToken = _price;
        feePerToken = _fee;
    }

    // Returns the total price for the passed quantity of tokens
    function price(uint amt) public view returns (uint) {
        return pricePerToken * amt;
    }

    // Returns the total fee, given this quantity of tokens
    function fee(uint amt) public view returns (uint) {
        return feePerToken * amt;
    }

    // Caller buys tokens from this contract
    function sellToCaller(address to, uint amount) public payable override {
        require(amount > 0, "amount must be valid to sell");
        if(balanceOf(address(this)) < amount){
            mint(amount);
        }
        uint previousToAmount = balanceOf(to);
        uint totalCost = price(amount) + fee(amount); // we are carrying this out in single transaction
        require(msg.value >= totalCost, "mgr: message has enough value to carry out a transaction");
        require(currency.transfer(to,amount),"unsuccesful transfer of tokens during selling");
        require(balanceOf(address(to)) == previousToAmount + amount, "the to address gained the correct amount");
    }


    // Caller sells tokens to this contract
    function buyFromCaller(uint amount) public payable {
        require(amount > 0, "amount must be valid to buy");
        require(
            balanceOf(address(msg.sender)) >= amount,
            "Seller has insufficient tokens"
        );


        uint previousTokenAmount = balanceOf(address(msg.sender));
        uint payment = price(amount) + fee(amount);
        require(
            address(this).balance >= payment,
            "Contract has insufficient ETH"
        );
        require(currency.transfer(address(this), amount), "transfer unsuccessful during buying"); // 
        payable(msg.sender).transfer(payment);  // check syntax 
        require(balanceOf(address(msg.sender)) == previousTokenAmount - amount, "did not reduce the amount of token owned by the caller");
    }

    // Create some new tokens, and give them to this TokenManager
    function mint(uint amount) public onlyOwner {
        _totalSupply += amount;
        balances[address(this)] += amount;
    }

    // Destroy some existing tokens, that are owned by this TokenManager
    function melt(uint amount) external onlyOwner {
        require(
            balanceOf(address(this)) >= amount,
            "Insufficient tokens to melt"
        );
        _totalSupply -= amount;
        balances[address(this)] -= amount;
    }
}

contract AATest {
    event Log(string info);

    function TestBuyRemit() public payable returns (uint) {
        emit Log("trying TestBuyRemit");
        TokenManager tok1 = new TokenManager(100, 1);
        TokenHolder h1 = new TokenHolder(tok1);

        uint amt = 2;
        tok1.sellToCaller{value: tok1.price(amt) + tok1.fee(amt)}(
            address(h1),
            amt
        );
        assert(tok1.balanceOf(address(h1)) == amt);

        h1.remit{value: tok1.fee(amt)}(1, 50, tok1);
        assert(tok1.balanceOf(address(h1)) == 1);
        assert(tok1.balanceOf(address(tok1)) == 1);

        return tok1.price(1);
    }

    function FailBuyBadFee() public payable {
        TokenManager tok1 = new TokenManager(100, 1);
        TokenHolder h1 = new TokenHolder(tok1);

        uint amt = 2;
        tok1.sellToCaller{value: 1}(address(h1), amt);
        assert(tok1.balanceOf(address(h1)) == 2);
    }

    function FailRemitBadFee() public payable {
        TokenManager tok1 = new TokenManager(100, 1);
        TokenHolder h1 = new TokenHolder(tok1);

        uint amt = 2;
        tok1.sellToCaller{value: tok1.price(amt) + tok1.fee(amt)}(
            address(h1),
            amt
        );
        assert(tok1.balanceOf(address(h1)) == amt);
        emit Log("buy complete");

        h1.remit{value: tok1.fee(amt - 1)}(2, 50, tok1);
    }

    function TestHolderTransfer() public payable {
        TokenManager tok1 = new TokenManager(100, 1);
        TokenHolder h1 = new TokenHolder(tok1);
        TokenHolder h2 = new TokenHolder(tok1);

        uint amt = 2;
        tok1.sellToCaller{value: tok1.price(amt) + tok1.fee(amt)}(
            address(h1),
            amt
        );
        assert(tok1.balanceOf(address(h1)) == amt);

        h1.putUpForSale(2, 200);
        h2.buy{value: 2 * 202}(1, 202, h1);
        h2.buy(1, 202, h1); // Since I loaded money the first time, its still there now.
    }

}
