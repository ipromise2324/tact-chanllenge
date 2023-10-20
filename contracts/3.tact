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
    let token: Address = sender();
    let myBalance: Int = 0;
    let tokenBalance: Int = 0;
    let sendToken: Address = token;

    if(token == self.jettonAddressA) {
        myBalance = self.aAmount;
        tokenBalance = self.bAmount;
        sendToken = self.jettonAddressB;
    } else if(token == self.jettonAddressB) {
        myBalance = self.bAmount;
        tokenBalance = self.aAmount;
        sendToken = self.jettonAddressA;
    } else {
        throw(0xffffff);
    }
    
    let msg_from: Address = msg.from;
    let msg_amount: Int = msg.amount;

    if(msg_from == self.owner) {
        myBalance = myBalance + msg_amount;
    }
    else {
        let amountToSend: Int = (tokenBalance * 1000000000 / myBalance) * msg_amount / 1000000000;
        if (amountToSend > myBalance) {
            send(SendParameters{
                to: token,
                value: 0,
                mode: 64,
                body: TokenTransfer{
                    queryId: 0,
                    amount: msg_amount,
                    destination: msg_from,
                    responseDestination: myAddress(),
                    customPayload: null,
                    forwardTonAmount: ton("0.01"),
                    forwardPayload: emptySlice()
                }.toCell()
            });
        } else {
            myBalance = myBalance + msg_amount;
            tokenBalance = tokenBalance - amountToSend;
            send(SendParameters{
                to: sendToken,
                value: 0,
                mode: 64,
                body: TokenTransfer{
                    queryId: 0,
                    amount: amountToSend,
                    destination: msg_from,
                    responseDestination: myAddress(),
                    customPayload: null,
                    forwardTonAmount: ton("0.01"),
                    forwardPayload: emptySlice()
                }.toCell()
            });
        }
    }

    if (token == self.jettonAddressA) {
        self.aAmount = myBalance;
        self.bAmount = tokenBalance;
    } else {
        self.aAmount = tokenBalance;
        self.bAmount = myBalance;
    }
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