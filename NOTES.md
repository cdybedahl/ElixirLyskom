* Socket gets bytes over the network.

* Socket sends them to Tokenizer.

* Tokenizer append to data in state, and send a message to itself to process data.

* Tokenizer recurses over data one byte at a time, keeping state on what it's looking at.

* When tokenizer has a full token, it sends it to Parser.

* Parser stores tokens. When it gets an end-of-message token, it does array processing on what it has, then sends the whole message to Server.
