import "@stdlib/deploy";

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
    aAmount: Int;
    bAmount: Int;
    jettonAddressA: Address;
    jettonAddressB: Address;
    decimal: Int;

    init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
        self.owner = admin;
        self.jettonAddressA = newJettonAddressA;
        self.jettonAddressB = newJettonAddressB;
        self.aAmount = 0;
        self.bAmount = 0;
        self.decimal = 1000000000;
    }

  receive(msg: TokenNotification) {
    let ctx_sender: Address = sender();
    if (sender() == self.jettonAddressB) { 
        if (msg.from == self.owner) {
            self.bAmount = self.bAmount + msg.amount;
            return;
        }
      let aAmountToSend: Int = self.aAmount * 1000000000 / self.bAmount * msg.amount / 1000000000;
        if (aAmountToSend > self.aAmount) {
            send(SendParameters{
                to: self.jettonAddressB,
                value: 0,
                mode: 64,
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
        mode: 64,
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
    }else if (sender() == self.jettonAddressA) {
      if (msg.from == self.owner) {
        self.aAmount = self.aAmount + msg.amount;
        return;
      }
      let bAmountToSend: Int = self.bAmount * 1000000000 / self.aAmount * msg.amount / 1000000000;
      if (bAmountToSend > self.bAmount) {
        send(SendParameters{
          to: self.jettonAddressA,
          value: 0,
          mode: 64,
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
        mode: 64,
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
      return self.bAmount * 1000000000 / self.aAmount;
    }
    return self.aAmount * 1000000000 / self.bAmount;
  }
  
  get fun balance(jetton: Address): Int {
    if(jetton == self.jettonAddressA) {
      return self.aAmount;
    }
    return self.bAmount;
  }

}