#!/usr/bin/env bash

RH_CORE_DIR=${HOME}/RedHat/rh-core
INSTALL_DIR=${RH_CORE_DIR}/install
#PATH=${PATH}:${INSTALL_DIR}/sbin:${INSTALL_DIR}/bin
#PYTHONPATH=${INSTALL_DIR}/lib64/python3.10/site-packages:${INSTALL_DIR}/lib/python3.10/site-packages

# Install broker instance (if not already done)

if [[ -d broker ]]; then
    if [[ -e broker/bin/artemis-service ]]; then
        echo "Artemis broker found"
    else
        echo "Artemis broker not found, re-install"
        exit 1
    fi
else
    ARTEMIS_DIR=`ls -d ${RH_CORE_DIR}/activemq-artemis/artemis-distribution/target/apache-artemis*-bin`
    echo "ARTEMIS_DIR=${ARTEMIS_DIR}"
    ARTEMIS_BASE_DIR=${ARTEMIS_DIR##*/}
    echo "ARTEMIS_BASE_DIR=${ARTEMIS_BASE_DIR}"
    ARTEMIS_VER=${ARTEMIS_BASE_DIR%-*}
    echo "ARTEMIS_VER=${ARTEMIS_VER}"

    ${ARTEMIS_DIR}/${ARTEMIS_VER}/bin/artemis create broker --force --user admin --password admin --role amq --allow-anonymous

    # Update config file to listen on port 9001, turn off persistence
    sed -i 's|<persistence-enabled>true</persistence-enabled>|<persistence-enabled>false</persistence-enabled>|' broker/etc/broker.xml
    sed -i 's|<acceptor name="amqp">tcp://0.0.0.0:5672?|<acceptor name="amqp">tcp://0.0.0.0:9001?|' broker/etc/broker.xml
fi

# Start broker
broker/bin/artemis version
broker/bin/artemis run
