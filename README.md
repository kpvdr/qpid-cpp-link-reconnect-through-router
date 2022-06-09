# qpid-cpp-link-reconnect-through-router
Demonstration of how to write a C++ qpid-proton client to re-establish a link that is lost (without the connection going down) through a router network.

When the qpid-dispatch-router's linkRoute is used to connect a client and a broker, the failure of the broker results in the client seeing the links closing (AMQP detatch), but the connection remains open. This test shows how a client can detect and handle this occurrence, and how to re-establish the link on this connection when the broker comes back up.

# Client behavior
The client will send messages at one second intervals. It is important to note that the callbacks used in the client message handler are part of an event-loop, so **do not use sleep()** in this code! The timed interval is achieved by using the client's work queue to trigger a callback to send a message.

When the broker fails, the sender is closed. The on_sender_close() callback is used to attempt to create a new sender on the same connection once every two seconds. For as long as the broker is down, each new sender will be immediately closed again.

When the broker is re-established, then creating a new sender will succeed with credit, and will remain open. The sender can then resume sending messages.

# Prerequisites

## Fedora
The following packages should be installed:

* qpid-proton-c
* qpid-proton-c-devel
* qpid-proton-cpp
* qpid-proton-cpp-devel
* qpid-dispatch-router
* python3-qpid-proton (required by qpid-dispatch-tools)
* qpid-dispatch-tools (optional)

and necessary tools such as:

* make
* cmake
* gcc-c++
* valgrind

This can be achieved with:
```
sudo dnf install qpid-dispatch-router qpid-proton-cpp-devel cmake gcc-c++ valgrind
```
and the remaining packages are automatically installed from dependencies.

## Other distros
I have neither tested nor run other distros at this time. Some tweaking of package names may be required.

# How to run the test using Makefile
Use `make --help` to see a synopsis.

1. Start broker:

   `make start-broker` will create a new broker instance, modify it to listen on port 9001 and start it in a new interactive terminal window. This allows the user to stop the broker (`^C`) and restart it at will using command `scripts/start-broker.sh`. Type `exit` to close the window once the broker is stopped.

1. Start router(s):

   For the one-node test, `make start-router` will start the router in a new window (non-interactive, will close when stopped with `^C`).

   or

   For the two-node test, `make start-b-router`, then `make start-c-router` will start the two routers in a new non-interactive window each.

1. Run client:

   `make send` will build, start the client. It will send 20 messages at 1 second intervals. The client is started under valgrind's memory checker with the following parameters:
   ```
   sender -a amqp://127.0.0.1/link1.test -m 20
   ```

1. Stop the broker while the client is sending, then restart it:

    Find the broker window, then:
    ```
    ^C
    <broker stops>
    ```
    Check the client window to see that the client has entered a loop attempting to restart the sender. Then restart the broker:
    ```
    ./scripts/start-broker.sh
    <broker starts>
    ```

1. Check the client window for successful sender restart and for message sending to continue where it was interrupted.

# How to run the test without Makefile

1. Build the client:
    ```
    mkdir bld
    cd bld
    cmake ..
    make
    cd ..
    ```
1. Start the broker in a new bash terminal:
    ```
    ./scripts/start-broker.sh
    ```
    This will create a new broker instance (if it does not exist), modify it to listen on port 9001, then start it.

1. Start the router node(s) in a new bash terminal each:

    For single node case:
    ```
    qdrouterd --conf single-node.conf
    ```
    For two node case:
    ```
    qdrouterd --conf dual-node-broker-side.conf
    ```
    and
    ```
    qdrouterd --conf dual-node-client-side.conf
    ```

1. Run the client:
    ```
    ./bld/sender -a amqp://127.0.0.1/link1.test -m 20
    ```
    Running `sender --help` will provide a list of parameters that may be used:
    ```
    usage: sender [options]

    options:
      -h, --help
            Print the help message
      -a URL, --address=URL
            Connect and send to URL (default )
      -u USER, --user=USER
            Authenticate as USER (default )
      -p PWD, --password=PWD
            Authenticate with PWD (default )
      -r, --reconnect
            Reconnect on connection failure
      -m COUNT, --messages=COUNT
            Send COUNT messages (default 100)
      -i INT, --interval=INT
            Send BURST messages every INT milliseconds (default 1000)
      -s INT, --sender-retry-interval=INT
            Retry to open sender every INT milliseconds when link drops (default 2000)
      -b COUNT, --burst=COUNT
            Send COUNT messages at a time each interval (default 1)
    ```
    | Short | Long | Description | Default | Req'd |
    | --- | --- | --- | --- | --- |
    | -h | --help | Print the help message |  |  |
    | -a URL | --address URL | Connect and send to URL |  | Y |
    | -u USER | --user USER | Authenticate as USER |  |  |
    | -p PWD | --password PWD | Authenticate with PASSWORD |  |  |
    | -r | --reconnect | Reconnect on connection failure | N |  |
    | -m COUNT | --messages COUNT | Send COUNT total messages | 100 |  |
    | -i INT | --interval INT | Send BURST messages every INT milliseconds | 1000 |  |
    | -s INT | --sender-retry-interval INT | Retry to open sender every INT milliseconds when link drops | 2000 |  |
    | -b COUNT | --burst COUNT | Send BURST messages at a time each interval | 1 |  |

1. Stop the broker while the client is sending, then restart it:

    In the broker window:
    ```
    ^C
    <broker stops>
    ```
    Check the client window to see that the client has entered a loop attempting to restart the sender. Then restart the broker:
    ```
    ./scripts/start-broker.sh
    <broker starts>
    ```
1. Check the client window for successful sender restart and for message sending to continue where it was interrupted.

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
