# Ethereum Tokens

In this assignment you will work with ERC223 tokens.  ERC223 tokens are a superset of ERC20 tokens; they fix a key problem which is to prevent the accidental sending of tokens to a contract that is not capable of spending them.  You can read more details here: https://github.com/Dexaran/ERC223-token-standard.  The assignment files contains the IERC223.sol interface file, a basic implementation in ERC223.sol, and some supporting files.

You will build a token manager contract whose job is to provide (mint) and redeem (melt) tokens on demand.  When your token manager mints and melts tokens, the contract will receive or pay out ethereum in compensation for the tokens.  The contract will always mint/melt at a single exchange rate, specified in the contract's constructor, but of course in Real Life<sup>(tm)</sup> such a contract would have additional code that dynamically adjusts the exchange rate based on market activity. 

You will then implement a contract that is capable of holding tokens (named TokenHolder).  Again, this is a smaller piece of what you might do in Real Life<sup>(tm)</sup>.  For example, you might make a contract that arbitrages differences in USDC and USDT tokens (recall that both of these tokens claim to be US dollar equivalents, but in fact their real price in USD tends to vary by as much as 1%), and so your single contract would need to be able to manage holdings of 2 token types (presumably by instantiating two "TokenHolder" objects).


My tests will instantiate the classes you implement and test moving tokens between holders and the market makers, and from one holder to another.  DO NOT CHANGE ANY INTERFACES!


0. Upload all of the .sol files in this archive into the remix IDE.

1. Implement a "TokenHolder" contract that derives from ITokenHolder.  Implement the TokenManager contract (located in tokenMgr.sol).  The TokenManager creates the token type, and mints and melts tokens on demand, at a defined exchange rate.  Its basically the market maker and provides an essentially infinite "pool" of tokens to draw from.  Therefore it is BOTH an ERC223Token and a TokenHolder.

Token sales occur in 2 steps.  The TokenHolder must first make some tokens available for sale by calling "putUpForSale".  Then the buyer can call the "sellToCaller" function (with the appropriate payment) and this function will transfer tokens from seller to buyer.

2.  To move tokens between 2 contracts without a sale (presumably owned by the same entity), implement the "withdraw" function.  Hint: This is a 1-liner.

3. Implement "remit" which sells tokens back to the token manager.  This is a little bit of a special case because anyone can tell the TokenMgr to initiate a buy (whereas the normal TokenHolder only buys if the owner tells it to).  (Hint, use the TokenManager's buyFromCaller function).  Implement TokenManager.buyFromCaller.


4. Implement all the other helper functions.

5. I've included 2 simple tests.  I recommend you write more.  COMMENT ALL OF THESE TEST CLASSES OUT OF YOUR FINAL SUBMISSION!!! They will likely cause your code to hit the contract size limits in a "real" testnet verses the remix simulator.


Don't forget to add the appropriate require statements to ensure that the money and tokens are appropriately transfered.  Remember that two TokenHolders or a TokenHolder and a TokenManager are INDEPENDENT, COMPETITIVE entities.  So they will steal tokens from eachother if possible!


Submit a single file called tokenMgr.sol (You don't need to make a .zip file if submitting just one file).
