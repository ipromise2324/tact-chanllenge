import "@stdlib/deploy";

message Add {
  queryId: Int as uint64; 
  number: Int as uint32; 
}

message Subtract {
  queryId: Int as uint64;
  number: Int as uint32;  
}

contract Task1 with Deployable {
    c: Int as int32 = 0;
    init() {}
    receive(msg: Add) {self.c = self.c + msg.number ;}
    receive(msg: Subtract) {self.c = self.c - msg.number;}
    get fun counter(): Int {return self.c;}
}

