import "@stdlib/deploy";

message(0x44) Refund {
    queryId: Int as uint64;
    sender: Address;
}

contract Task2 with Deployable {
    admin: Address;
    init(admin: Address){
        self.admin = admin;
    }

    receive(msg: Refund){
        require(sender() == self.admin, "Only Owner");
        send(SendParameters{
                to: msg.sender, 
                value: 0, 
                mode: SendRemainingValue
        });
    }

    receive(msg: Slice){
        send(SendParameters{
            to: self.admin,
            value: 0,
            mode: SendRemainingValue,
            body: beginCell().storeAddress(sender()).storeRef(msg.asCell()).endCell()
        });
    }
}