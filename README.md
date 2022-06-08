# qpid-cpp-link-reconnect-through-router
Demonstration of how to write a C++ qpid-proton client to re-establish a link that is lost (without the connection going down) through a router network.

When the qpid-dispatch-router's linkRoute is used to connect a client and a broker, the failure of the broker results in the client seeing the links closing (AMQP detatch), but the connection remains open. This test shows how a client can detect and handle this occurrence, and how to re-establish the link on this connection when the broker comes back up.

# Client behavior
The client will send messages at 1 second intervals. It is important to note that the callbacks used in the client message handler are part of an event-loop, so **do not use sleep()** in this code! The timed interval is achieved by using the client's work queue to trigger a callback to send a message.

When the broker fails, the sender is closed. The on_sender_close() callback is used to attempt to create a new sender on the same connection once per second. For as long as the broker is down, each new sender will be immediately closed again.

When the broker is re-established, then creating a new sender will succeed with credit, and will remain open. The sender can then resume sending messages.

# How to run the test
Use make --help to see a synopsis.

1. Start broker
   make start-broker will create a new broker instance, modify it to listen on port 9001 and start it in a new interactive terminal window. This allows the user to stop the broker and restart it at will. Type exit to close the window once the broker is stopped.
1. Start router(s)
   For the one-node test, make start-router
   For the two-node test, make start-b-router, then make start-c-router
1. Run client
   make send
   This will build, then send 20 messages at 1 second intervals.
