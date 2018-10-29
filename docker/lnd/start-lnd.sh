#!/usr/bin/env bash

# exit from script if error was raised.
set -e

# error function is used within a bash function in order to send the error
# message directly to the stderr output and exit.
error() {
    echo "$1" > /dev/stderr
    exit 0
}

# return is used within bash function in order to return the value.
return() {
    echo "$1"
}

# set_default function gives the ability to move the setting of default
# env variable from docker file to the script thereby giving the ability to the
# user override it durin container start.
set_default() {
    # docker initialized env variables with blank string and we can't just
    # use -z flag as usually.
    BLANK_STRING='""'

    VARIABLE="$1"
    DEFAULT="$2"

    if [[ -z "$VARIABLE" || "$VARIABLE" == "$BLANK_STRING" ]]; then

        if [ -z "$DEFAULT" ]; then
            error "You should specify default variable"
        else
            VARIABLE="$DEFAULT"
        fi
    fi

   return "$VARIABLE"
}

# Set default variables if needed.
RPCUSER=$(set_default "$RPCUSER" "kek")
RPCPASS=$(set_default "$RPCPASS" "kek")
DEBUG=$(set_default "$DEBUG" "debug")
NETWORK=$(set_default "$NETWORK" "simnet")
CHAIN=$(set_default "$CHAIN" "bitcoin")
USERID=$(set_default "$USERID" "0")
BACKEND="btcd"
if [[ "$CHAIN" == "litecoin" ]]; then
    BACKEND="ltcd"
fi

exec  mkdir "/rpc/lnd-$USERID" & lnd \
    --rpclisten="0.0.0.0:10001" \
    --listen="0.0.0.0:10011" \
    --restlisten="0.0.0.0:8001" \
    --datadir="/k8s/data" \
    --logdir="/k8s/log" \
    --debuglevel="info" \
    --tlscertpath="/rpc/lnd-$USERID/tls.cert" \
    --no-macaroons \
    "--$CHAIN.active" \
    "--$CHAIN.$NETWORK" \
    "--$CHAIN.node"="btcd" \
    "--$BACKEND.rpccert"="/rpc/bitcoin/rpc.cert" \
    "--$BACKEND.rpchost"="142.93.13.155" \
    "--$BACKEND.rpcuser"="$RPCUSER" \
    "--$BACKEND.rpcpass"="$RPCPASS" \
    "$@"
