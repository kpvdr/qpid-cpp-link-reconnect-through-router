TERM:=gnome-terminal
WAIT_FOR_EXIT:="echo 'Press Enter to exit'; read line"

.PHONY: help
help:
	@echo "Demo of Qpid C++ link restart on existing connection:"
	@echo "  build:              Build test"
	@echo "  clean:              Delete bld directory with all build artifacts"
	@echo "  start-broker        Start Artemis broker in new *interactive* terminal window"
	@echo "  start-b-router      Start broker-side router (2-node case) in new terminal window"
	@echo "  start-c-router      Start client-side router (2-node case) in new terminal window"
	@echo "  start-router        Start router (1-node case) in new terminal window"
	@echo "  send                Build cleint, then send 20 messages to broker through router(s)"
	@echo
	@echo "Suggested execution for 2-node router case:"
	@echo "  $$ make start-broker"
	@echo "  $$ make start-b-router"
	@echo "  $$ make start-c-router"
	@echo "  $$ make send"
	@echo "  When messages are being sent, go to broker window, ^C broker,"
	@echo "    then restart broker with 'scripts/start-broker.sh'"
	@echo "  Watch this window for link restore and continuation of message sending"


.PHONY: clean
clean:
	@rm -rf bld/ broker/

.PHONY: build
build: bld/sender

bld/sender:
	scripts/build.sh

.PHONY: start-broker
start-broker:
	${TERM} -- bash --init-file scripts/start-broker.sh

.PHONY: start-b-router
start-b-router:
	${TERM} -- qdrouterd --config dual-node-broker-side.conf

.PHONY: start-c-router
start-c-router:
	${TERM} -- qdrouterd --config dual-node-client-side.conf

.PHONY: start-router
start-router:
	${TERM} -- qdrouterd --config single-node.conf

.PHONY: send
send: build
	valgrind --leak-check=full ./bld/sender -a amqp://127.0.0.1/link1.test -m 20
