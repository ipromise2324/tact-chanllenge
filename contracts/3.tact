import "@stdlib/deploy";
const d: Int = 1000000000;
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
     queryId: Int as uint64; // should be 0
     amount: Int as coins; // should be amount of jettons to send
     destination: Address; // should be user address / TokenNotification.from
     responseDestination: Address?; // should be myAddress()
     customPayload: Cell?; // should be null
     forwardTonAmount: Int as coins; // should be ton("0.01")
     forwardPayload: Slice as remaining; // should be emptySlice()
}


contract Task3 with Deployable {
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
  }

  receive(msg: TokenNotification) {
    let ctx_sender: Address = sender();
    // received jetton B
    if (ctx_sender == self.jettonAddressB) { 
      if (msg.from == self.owner) {
        self.bAmount = self.bAmount + msg.amount;
        return;
      }
      let aAmountToSend: Int = (self.aAmount * d / self.bAmount) * msg.amount / d;
        if (aAmountToSend > self.aAmount) {
            send(SendParameters{
            to: self.jettonAddressB,
            value: 0,
            mode: SendRemainingValue,
            body: TokenTransfer{
            queryId: 0,
            amount: msg.amount,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: emptySlice()
            }.toCell()
        });
        return;
        } 
        self.bAmount = self.bAmount + msg.amount;
        self.aAmount = self.aAmount - aAmountToSend;
        send(SendParameters{
        to: self.jettonAddressA,
        value: 0,
        mode: SendRemainingValue,
        body: TokenTransfer{
            queryId: 0,
            amount: aAmountToSend,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: emptySlice()
        }.toCell()
        });
        return;
    }else if (ctx_sender == self.jettonAddressA) {
        if (msg.from == self.owner) {
            self.aAmount = self.aAmount + msg.amount;
            return;
        }
      let bAmountToSend: Int = (self.bAmount * d / self.aAmount) * msg.amount / d;
        if (bAmountToSend > self.bAmount) {
        send(SendParameters{
            to: self.jettonAddressA,
            value: 0,
            mode: SendRemainingValue,
            body: TokenTransfer{
                queryId: 0,
                amount: msg.amount,
                destination: msg.from,
                responseDestination: myAddress(),
                customPayload: null,
                forwardTonAmount: ton("0.01"),
            forwardPayload: emptySlice()
            }.toCell()
        });
        return;
      }
      self.aAmount = self.aAmount + msg.amount;
      self.bAmount = self.bAmount - bAmountToSend;
      send(SendParameters{
        to: self.jettonAddressB,
        value: 0,
        mode: SendRemainingValue,
        body: TokenTransfer{
            queryId: 0,
            amount: bAmountToSend,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: emptySlice()
            }.toCell()
        });
        return;
    }
    throw(0xffffff);
  } 
  
  get fun price(jetton: Address): Int {
    if(jetton == self.jettonAddressA) {
      return self.bAmount * d / self.aAmount;
    }
    return self.aAmount * d / self.bAmount;
  }
  
  get fun balance(jetton: Address): Int {
    if(jetton == self.jettonAddressA) {
      return self.aAmount;
    }
    return self.bAmount;
  }

}