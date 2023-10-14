import "@stdlib/deploy";
message(0x44) Refund {
    queryId: Int as uint64;
    sender: Address;
}
contract Admin with Deployable {
    owner: Address;
    queryId: Int;
    init(owner: Address) {
        self.owner = owner;
        self.queryId = 0;
    }

    receive(msg: Slice) {
        dump("RECEIVE");
        let user: Address = msg.loadAddress();
        let ref: Cell = msg.loadRef();
        self.queryId = self.queryId + 1;

    }

    receive(msg: Refund) {
        send(SendParameters{
            to: msg.sender,
            value: 0,
            bounce: false,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: Refund {
                queryId: self.queryId,
                sender: context().sender
            }.toCell()
        });
    }

    get fun get_queryId(): Int {
        return self.queryId;
    }
}
