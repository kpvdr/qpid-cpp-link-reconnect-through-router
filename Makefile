# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.


TERM:=gnome-terminal

.PHONY: help
help:
	@echo "Demo of Qpid C++ link restart on existing connection:"
	@echo "make options:"
	@echo "  build:              Build test"
	@echo "  clean:              Delete bld directory with all build artifacts"
	@echo "  start-broker        Start Artemis broker in new *interactive* terminal window"
	@echo "  start-b-router      Start broker-side router (dual-node case) in new terminal window"
	@echo "  start-c-router      Start client-side router (dual-node case) in new terminal window"
	@echo "  start-router        Start router (1-node case) in new terminal window"
	@echo "  send                Build cleint, then send 20 messages to broker through router(s)"
	@echo
	@echo "Demo single-node configuration:"
	@echo "  sender --[5672]--> router --[9001]--> broker"
	@echo
	@echo "Demo dual-node configuration:"
	@echo "  sender --[5672]--> c-router --[8001]--> b-router --[9001]--> broker"
	@echo
	@echo "Suggested execution for single-node router case:"
	@echo "  $$ make start-broker"
	@echo "  $$ make start-router"
	@echo "  $$ make send"
	@echo
	@echo "Suggested execution for dual-node router case:"
	@echo "  $$ make start-broker"
	@echo "  $$ make start-b-router"
	@echo "  $$ make start-c-router"
	@echo "  $$ make send"
	@echo
	@echo "  While messages are being sent, go to broker window, ^C broker,"
	@echo "    then restart broker with 'scripts/start-broker.sh'"
	@echo "  Watch this window for link restore and continuation of message sending"
	@echo "  When all messages are received, ^C the routers and broker. To close the"
	@echo "  broker window, use \"exit\"."


.PHONY: clean
clean:
	@rm -rf bld/ broker/

.PHONY: build
build: bld/sender

bld/sender: src/options.hpp src/sender.cpp
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
