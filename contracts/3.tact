import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  If smart contract pool doesn't have enough jettons to trade
  (for example someone sends 99999 jettons of B, but dex pool only has 10 of jettons A),
  then sent incoming jettons (B, in our example) back to the sender.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract Task3 with Deployable {
  owner: Address;
  a: Int;
  b: Int;
  jAddressA: Address;
  jAddressB: Address;
  decimal: Int;

  init(admin: Address, newJAddressA: Address, newJAddressB: Address) {
    self.owner = admin;
    self.jAddressA = newJAddressA;
    self.jAddressB = newJAddressB;
    self.a = 0;
    self.b = 0;
    self.decimal = 1000000000;
  }

  receive(msg: TokenNotification) {
    let ctx: Context = context();
    let notOwner: Bool = ctx.sender != self.owner;
    let sendBool: Int = 0;
    let amount: Int = 0;
    if(ctx.sender == self.jAddressA) {
      if(notOwner) {
        amount = msg.amount * self.b / self.a / self.decimal;
        if (amount > 0 && amount >= self.b){
          sendBool = 1;
          send(SendParameters{
            to: self.jAddressB,
            value: 0,
            bounce: false,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: TokenTransfer{
              queryId: 0,
              amount: amount,
              destination: msg.from,
              responseDestination: null,
              customPayload: null,
              forwardTonAmount: 0,
              forwardPayload: emptySlice()
            }.toCell()
          });
        }
      }
      if(amount >= self.b) {
        self.a = self.a + msg.amount;
      }
    } else if(ctx.sender == self.jAddressB) {
      if(notOwner) {
        amount = msg.amount * self.a / self.b / self.decimal;
          if (amount > 0 && amount >= self.a) {
          sendBool = 1;
          send(SendParameters{
            to: self.jAddressA,
            value: 0,
            bounce: false,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: TokenTransfer{
              queryId: 0,
              amount: amount,
              destination: msg.from,
              responseDestination: null,
              customPayload: null,
              forwardTonAmount: 0,
              forwardPayload: emptySlice()
            }.toCell()
          });
        }
      }
      if(amount >= self.a) {
        self.b = self.b + msg.amount;
      }
    }
    if(sendBool == 0 && notOwner) {
      send(SendParameters{
        to: ctx.sender,
        value: 0,
        bounce: false,
        mode: SendRemainingValue + SendIgnoreErrors,
        body: TokenTransfer{
          queryId: 0,
          amount: msg.amount,
          destination: msg.from,
          responseDestination: null,
          customPayload: null,
          forwardTonAmount: 0,
          forwardPayload: emptySlice()
        }.toCell()
      });
    }
    
  }

  get fun price(token: Address): Int {
    if(token == self.jAddressA) {
      return self.b / self.a;
    }
    return self.a / self.b;
  }
  
  get fun balance(token: Address): Int {
    if(token == self.jAddressA) {
      return self.a;
    } 
    return self.b;
  }
}