import "@stdlib/deploy";


const thesheld: Int = 91;
message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}


message WorkerSendNFTs {
  startIdx: Int as uint16;
  queryId: Int as uint64;
  tn: Cell;
}


message AdminFetchProfit {
  queryId: Int as uint64;
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64;            
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining; 
}

contract Task5 with Deployable {
  owner: Address;
  nfts: map<Int as uint16, Address>;
  totalNftsHeld: Int as uint16 = 0;
  
  init(seed: Int, owner: Address) {
    self.owner = owner;
  }


  receive(msg: OwnershipAssigned) {
    if(msg.prevOwner == self.owner) {
      self.nfts.set(self.totalNftsHeld, sender());
      self.totalNftsHeld = self.totalNftsHeld + 1;
      return;
    }

    if(context().value < ton("2.1")) {
      send(SendParameters{
        to: sender(),
        value: 0,
        mode: 96,
        body: Transfer { 
          queryId: msg.queryId,            
          newOwner: msg.prevOwner, 
          responseDestination: msg.prevOwner, 
          customPayload: null, 
          forwardAmount: 0, 
          forwardPayload: emptySlice() 
        }.toCell()
      });
      return;
    }

    nativeReserve(ton("2"), 0);
    let rndIdx: Int = random(0, self.totalNftsHeld);
    if (rndIdx == self.totalNftsHeld) {
      send(SendParameters{
        to: sender(),
        value: 0,
        mode: 96,
        body: Transfer { 
          queryId: msg.queryId,            
          newOwner: msg.prevOwner, 
          responseDestination: msg.prevOwner, 
          customPayload: null, 
          forwardAmount: 0, 
          forwardPayload: emptySlice() 
        }.toCell()
      });
      return;
    }
      send(SendParameters{
        to: self.nfts.get(rndIdx)!!,
        value: 0,
        mode: 96,
        body: Transfer { 
          queryId: msg.queryId,            
          newOwner: msg.prevOwner, 
          responseDestination: msg.prevOwner, 
          customPayload: null, 
          forwardAmount: 0, 
          forwardPayload: emptySlice() 
        }.toCell()
      });
      self.nfts.set(rndIdx, sender());
  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender()  == self.owner, "Insufficient privelegies");
    if (myBalance() > ton("0.1")) {
      nativeReserve(ton("0.1"), 0);
      send(SendParameters{
        to: self.owner,
        value: 0,
        mode: 128,
        body: AdminFetchProfit { 
          queryId: msg.queryId
        }.toCell()
      });
    }
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    require(context().value >= ton("1") + self.totalNftsHeld * ton("0.08"), "Insufficent funds");
    require(sender()  == self.owner, "Invalid sender");
    let count: Int = self.totalNftsHeld;
    let bodyTransfer: Cell = Transfer { 
      queryId: msg.queryId,            
      newOwner: self.owner, 
      responseDestination: self.owner,
      customPayload: null, 
      forwardAmount: 0, 
      forwardPayload: emptySlice()
    }.toCell();
    if (count < thesheld){
      let x: Int = 0;
      while(x < count) {
        send(SendParameters{
          to: self.nfts.get(x)!!,
          value: ton("0.01248"),
          mode: 0,
          body: bodyTransfer
        });
        x = x + 1;
      }
      return;
    }
    send(SendParameters{
        to: myAddress(),
        value: 0,
        mode: 64,
        body: WorkerSendNFTs { 
          queryId: msg.queryId,            
          startIdx: 0,
          tn: bodyTransfer
        }.toCell()
      });
  }

  receive(msg: WorkerSendNFTs) {
    let x: Int = msg.startIdx;
    let bodyTransfer: Cell = msg.tn;
    let count: Int = self.totalNftsHeld;
    let end: Int = msg.startIdx + thesheld;
    while(x < count && x < end) {
      send(SendParameters{
        to: self.nfts.get(x)!!,
        value: ton("0.01248"),
        mode: 0,
        body: bodyTransfer
      });
      x = x + 1;
    }
    if (x < count) {
      send(SendParameters{
        to: myAddress(),
        value: 0,
        mode: 64,
        body: WorkerSendNFTs{
          startIdx: x,
          queryId: msg.queryId,
          tn: bodyTransfer
        }.toCell()
      });
      return;
    }
    self.totalNftsHeld = 0;
    self.nfts = emptyMap();
  }

  get fun profit(): Int {
    if(myBalance() < ton("0.1")){
      return 0;
    }
    return myBalance() - ton("0.1");
  }
  
  get fun nfts(): map<Int as uint16, Address> {
    return self.nfts;
  }
}
