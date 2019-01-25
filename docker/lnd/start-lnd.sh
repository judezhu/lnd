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
RPCHOST=$(set_default "$RPCHOST" "45.63.36.223")
DEBUG=$(set_default "$DEBUG" "debug")
NETWORK=$(set_default "$NETWORK" "simnet")
CHAIN=$(set_default "$CHAIN" "bitcoin")
NODEID=$(set_default "$NODEID" "0")
COLOR=$(set_default "$COLOR" "#EAC14E")
BACKEND="btcd"
if [[ "$CHAIN" == "litecoin" ]]; then
    BACKEND="ltcd"
fi

LNDDIR="lnd/$NETWORK/$NODEID"
if [ ! -d "/rpc/$LNDDIR" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  mkdir -p "/rpc/$LNDDIR"
fi

if [ ! -d "/data/$LNDDIR" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  mkdir -p "/data/$LNDDIR"
fi

lnd \
  --rpclisten="0.0.0.0:10001" \
  --listen="0.0.0.0:10011" \
  --restlisten="0.0.0.0:8001" \
  --datadir="/data/$LNDDIR/data" \
  --logdir="/data/$LNDDIR/log" \
  --debuglevel="info" \
  --alias="$NODEID" \
  --color="$COLOR" \
  --tlscertpath="/rpc/$LNDDIR/tls.cert" \
  --tlskeypath="/rpc/$LNDDIR/tls.key" \
  --adminmacaroonpath="/rpc/$LNDDIR/admin.macaroon" \
  "--$CHAIN.active" \
  "--$CHAIN.$NETWORK" \
  "--$CHAIN.node"="btcd" \
  "--$BACKEND.rpccert"="/rpc/btcd/$NETWORK/rpc.cert" \
  "--$BACKEND.rpchost"="$RPCHOST" \
  "--$BACKEND.rpcuser"="$RPCUSER" \
  "--$BACKEND.rpcpass"="$RPCPASS" \
  "$@" \
  &

if [ -e "/rpc/$LNDDIR/admin.macaroon" ] && [ -e "/rpc/$LNDDIR/tls.cert" ]; then
  # if wallet already exists
  echo "Wallet exists. Waiting 30 sec to unlock wallet..."
  sleep 30s
  curl -X POST "https://makoto-dev.bleevin.cloud/wallet/v1/wallet/unlock?token=KnsUSZmvWouQRLHHRQYhiNpsqAHIYECDblDgIpHfUDCsLseAqKhfDMToZHeauNDesjEPiaGMmkxRMcDQpInHHwYlykZEFTyPfBPkuZdsMcjnQdbnTolAQvcDAxLPvzvRntCVNqjwcAfTBQOyzkTYYaOJGuKwGNAFLCdAZdHjVfYSQmxnRUgVIKRXGJgfuwZQjAtjpfgbQcXTvKhRkKwreBiFkWdUyFDeNjBGTeNxWhYqlTfKghjqkNrqshzFWikT&nodeId=$NODEID"
fi

if [ ! -e "/rpc/$LNDDIR/admin.macaroon" ] && [ -e "/rpc/$LNDDIR/tls.cert" ]; then
  # if wallet not exists
  echo "Wallet NOT exists. waiting 30 sec to create wallet..."
  sleep 30s
  curl -X POST "https://makoto-dev.bleevin.cloud/wallet/v1/wallet/create?token=KnsUSZmvWouQRLHHRQYhiNpsqAHIYECDblDgIpHfUDCsLseAqKhfDMToZHeauNDesjEPiaGMmkxRMcDQpInHHwYlykZEFTyPfBPkuZdsMcjnQdbnTolAQvcDAxLPvzvRntCVNqjwcAfTBQOyzkTYYaOJGuKwGNAFLCdAZdHjVfYSQmxnRUgVIKRXGJgfuwZQjAtjpfgbQcXTvKhRkKwreBiFkWdUyFDeNjBGTeNxWhYqlTfKghjqkNrqshzFWikT&nodeId=$NODEID"
fi
