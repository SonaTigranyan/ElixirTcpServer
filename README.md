Write a TCP server that receives messages from a client and writes back the client message.

Close the client connection whenever you receive the message “bye”.

The server should print the client number (+1 at every new client) when the client connects.

The server should log the client information (IP and port) to the console.

Make sure you use the application tree as well as GenServer.

Write a function that returns all the current connections (peer IPs and ports)

Write a function that when called closes all the connections.

