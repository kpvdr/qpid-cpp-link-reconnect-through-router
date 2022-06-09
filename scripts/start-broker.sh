#!/usr/bin/env bash

# Download Artemis from https://activemq.apache.org/components/artemis/download/
# Adjust this location if necessary:
ARTEMIS_INSTALL_DIR=${HOME}/Downloads/apache-artemis-2.22.0-bin

# Install broker instance (if not already done)

if [[ -d broker ]]; then
    # Broker instance found
    if [[ -e broker/bin/artemis-service ]]; then
        echo "Artemis broker found"
    else
        echo "Artemis broker not found, re-install"
        exit 1
    fi
else
    # No broker instance found - create it from the installed Artemis location
    ARTEMIS_DIR=`ls -d ${ARTEMIS_INSTALL_DIR}/apache-artemis*`
    echo "ARTEMIS_DIR=${ARTEMIS_DIR}"
    ARTEMIS_BASE_DIR=${ARTEMIS_DIR##*/}
    echo "ARTEMIS_BASE_DIR=${ARTEMIS_BASE_DIR}"
    if [[ ${ARTEMIS_BASE_DIR} == *-SNAPSHOT ]]; then
        ARTEMIS_VER=${ARTEMIS_BASE_DIR%-*}
    else
        ARTEMIS_VER=${ARTEMIS_BASE_DIR}
    fi
    echo "ARTEMIS_VER=${ARTEMIS_VER}"

    ${ARTEMIS_DIR}/bin/artemis create broker --force --user admin --password admin --role amq --allow-anonymous

    # Update broker instance config file to listen on port 9001, optionall turn off persistence
    #sed -i 's|<persistence-enabled>true</persistence-enabled>|<persistence-enabled>false</persistence-enabled>|' broker/etc/broker.xml
    sed -i 's|<acceptor name="amqp">tcp://0.0.0.0:5672?|<acceptor name="amqp">tcp://0.0.0.0:9001?|' broker/etc/broker.xml
fi

# Start broker
broker/bin/artemis version
broker/bin/artemis run
