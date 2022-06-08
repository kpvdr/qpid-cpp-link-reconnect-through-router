# qpid-cpp-link-reconnect-through-router
Demonstration of how to write a C++ qpid-proton client to re-establish a link that is lost (without the connection going down) through a router network.

When the qpid-dispatch-router's linkRoute is used to connect a client and a broker, the failure of the broker results in the client seeing the links closing (AMQP detatch), but the connection remains open. This test shows how a client can detect and handle this occurrence, and how to re-establish the link on this connection when the broker comes back up.

# Client behavior
The client will send messages at 1 second intervals. It is important to note that the callbacks used in the client message handler are part of an event-loop, so **do not use sleep()** in this code! The timed interval is achieved by using the client's work queue to trigger a callback to send a message.

When the broker fails, the sender is closed. The on_sender_close() callback is used to attempt to create a new sender on the same connection once per second. For as long as the broker is down, each new sender will be immediately closed again.

When the broker is re-established, then creating a new sender will succeed with credit, and will remain open. The sender can then resume sending messages.

# Prerequisites
The following packages should be installed:

* qpid-proton-c
* qpid-proton-cpp
* qpid-dispatch-router
* qpid-dispatch-tools (optional)
* python3-qpid-proton (required by qpid-dispatch-tools)

and necessary tools such as:

* make
* cmake
* gcc-c++

# How to run the test
Use `make --help` to see a synopsis.

1. Start broker:
   `make start-broker` will create a new broker instance, modify it to listen on port 9001 and start it in a new interactive terminal window. This allows the user to stop the broker and restart it at will using command `scripts/start-broker.sh`. Type `exit` to close the window once the broker is stopped.
1. Start router(s):
   For the one-node test, `make start-router`
   For the two-node test, `make start-b-router`, then `make start-c-router`
1. Run client:
   `make send`
   This will build, then send 20 messages at 1 second intervals.

# Expected output
```
$ make send
valgrind --leak-check=full ./bld/sender -a amqp://127.0.0.1/link1.test -m 20
==19286== Memcheck, a memory error detector
==19286== Copyright (C) 2002-2022, and GNU GPL'd, by Julian Seward et al.
==19286== Using Valgrind-3.19.0 and LibVEX; rerun with -h for copyright info
==19286== Command: ./bld/sender -a amqp://127.0.0.1/link1.test -m 20
==19286==
address: amqp://127.0.0.1/link1.test
user:
password:
reconnect: F
message_count: 20
on_sender_open: credit=true
on_sendable
sent=1
on_sendable
accepted: accepted=1 rejected=0 released=0
sent=2
on_sendable
accepted: accepted=2 rejected=0 released=0
sent=3
on_sendable
accepted: accepted=3 rejected=0 released=0
sent=4
on_sendable
accepted: accepted=4 rejected=0 released=0
sent=5
on_sendable
accepted: accepted=5 rejected=0 released=0

< broker killed here >

on_sender_error: qd:routed-link-lost: Connectivity to the peer container was lost
on_sender_close
reopen_sender - reopening sender, sent reset to 5
on_sender_open: credit=false
on_sender_error: qd:no-route-to-dest: No route to the destination node
on_sender_close
reopen_sender - reopening sender, sent reset to 5
on_sender_open: credit=false
on_sender_error: qd:no-route-to-dest: No route to the destination node
on_sender_close

< above 4 lines repeat at 1 sec. intervals until broker is re-established >

reopen_sender - reopening sender, sent reset to 5
on_sender_open: credit=true
on_sendable
sent=6
on_sendable
accepted: accepted=6 rejected=0 released=0
sent=7
on_sendable
accepted: accepted=7 rejected=0 released=0
sent=8

...

on_sendable
accepted: accepted=17 rejected=0 released=0
sent=18
on_sendable
accepted: accepted=18 rejected=0 released=0
sent=19
on_sendable
accepted: accepted=19 rejected=0 released=0
sent=20
on_sendable
accepted: accepted=20 rejected=0 released=0
all messages accepted
==19286==
==19286== HEAP SUMMARY:
==19286==     in use at exit: 13,387 bytes in 36 blocks
==19286==   total heap usage: 2,966 allocs, 2,930 frees, 475,929 bytes allocated
==19286==
==19286== LEAK SUMMARY:
==19286==    definitely lost: 0 bytes in 0 blocks
==19286==    indirectly lost: 0 bytes in 0 blocks
==19286==      possibly lost: 0 bytes in 0 blocks
==19286==    still reachable: 13,387 bytes in 36 blocks
==19286==         suppressed: 0 bytes in 0 blocks
==19286== Reachable blocks (those to which a pointer was found) are not shown.
==19286== To see them, rerun with: --leak-check=full --show-leak-kinds=all
==19286==
==19286== For lists of detected and suppressed errors, rerun with: -s
==19286== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)

```
