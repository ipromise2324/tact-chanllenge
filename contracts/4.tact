import "@stdlib/deploy";



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

message NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

contract Task4 with Deployable {
  seed: Int as uint128;
  lockTime: Int as uint32 = 0;
  nftAddress: Address? = null;
  nftOwner: Address? = null;
  
  init(seed: Int) {
    self.seed = seed;
  }

  receive(msg: OwnershipAssigned) {
    if(self.nftAddress != null) {
      // return nft back to sender
      send(SendParameters{
          to: sender(),
          value: 0,
          bounce: false,
          mode: 64,
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
    self.nftAddress = sender();
    self.lockTime = msg.forwardPayload.loadUint(32) + now();
    self.nftOwner = msg.prevOwner;
  }

  receive(msg: NftWithdrawal) {
    let ctx: Context  = context();
    require(ctx.sender == self.nftOwner, "Invalid sender");
    let comment: Cell = "NFT is still locked".asComment();
    if (now() < self.lockTime) {
      send(SendParameters{
        to: ctx.sender,
        value: 0,
        bounce: false,
        mode: 64,
        body: comment
      });
    } 
    else {
      // let balance: Int = myBalance();
      // balance = balance - ton("0.05");
      send(SendParameters{
          to: self.nftAddress!!,
          value: 0,
          bounce: false,
          mode: 64,
          body: Transfer { 
            queryId: msg.queryId,
            newOwner: self.nftOwner!!, 
            responseDestination: self.nftOwner!!,
            customPayload: null, 
            forwardAmount: 0, 
            forwardPayload: emptySlice()
          }.toCell()
      });
      send(SendParameters{
          to: ctx.sender,
          value: 0,
          bounce: true,
          mode: 128,
          body: comment
      });
      self.nftAddress = null;
      self.nftOwner = null;
      //self.lockTime = 0;
    }
  }

  get fun time(): Int {
    if (self.lockTime == 0 || now() > self.lockTime) {
      return 0;
    }
    return self.lockTime - now();
  }

  get fun nft(): Address? {
    return self.nftAddress;
  }

  get fun owner(): Address? {
    return self.nftOwner;
  }
}
