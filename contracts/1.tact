import "@stdlib/deploy";

/*
  TASK 1 - Counter contract 
  Implement counter contract that will have 2 opcodes ('Add' / 'Subtract'),
  which add or subtract the sent number (int32) with the number that stored in the state.
  Also, its needed to implement one getter with name "counter" to get the number from the store.
*/

message Add {
  queryId: Int as uint64; // Unique identifier for the query
  number: Int as uint32;  // The number to add to the counter
}

message Subtract {
  queryId: Int as uint64; // Unique identifier for the query
  number: Int as uint32;  // The number to subtract from the counter
}

contract Task1 with Deployable {
    counter: Int as int32;

    init() {
      self.counter = 0; // Initialize the counter to 0
    }

    receive(msg: Add) {
      self.counter = msg.number + self.counter; // Increase the counter
    }
    
    receive(msg: Subtract) {
      self.counter = self.counter - msg.number; 
    }

    get fun counter(): Int {
      return self.counter; 
    }
}

