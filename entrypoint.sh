#!/bin/bash

LOGGING="--log-level $LOG_LEVEL"

DAEMON_OPTIONS="--daemon-host $DAEMON_HOST --daemon-port $DAEMON_PORT"

# rpc login options
if [ -n "$RPC_USER" -a -n "$RPC_PASSWD" ]; then
  RPC_LOGIN="--rpc-login $RPC_USER:$RPC_PASSWD"
fi

# used for monerod and monero-wallet-rpc
RPC_OPTIONS="$LOGGING $RPC_LOGIN --confirm-external-bind --rpc-bind-ip $RPC_BIND_IP --rpc-bind-port $RPC_BIND_PORT"
# used for monerod
MONEROD_OPTIONS="--p2p-bind-ip $P2P_BIND_IP --p2p-bind-port $P2P_BIND_PORT"

MONEROD="monerod $@ $RPC_OPTIONS $MONEROD_OPTIONS --check-updates disabled"

# COMMAND="$@"

if [[ "${1:0:1}" = '-' ]]  || [[ -z "$@" ]]; then
  set -- $MONEROD
elif [[ "$1" = monero-wallet-rpc* ]]; then
  set -- "$@ $DAEMON_OPTIONS $RPC_OPTIONS"
elif [[ "$1" = monero-wallet-cli* ]]; then
  set -- "$@ $DAEMON_OPTIONS $LOGGING"
fi

echo "$@"

if [ "$USE_TOR" == "YES" ]; then
  chown -R debian-tor /var/lib/tor
  # run as daemon
  tor -f /etc/tor/torrc
fi

if [ "$USE_TORSOCKS" == "YES" ]; then
  set -- "torsocks $@"
fi

# allow the container to be started with `--user
if [ "$(id -u)" = 0 ]; then
  # USER_ID defaults to 1000 (Dockerfile)
  adduser --system --group --uid "$USER_ID" --shell /bin/false monero &> /dev/null

  if [ "$BLOCK" == "YES" ]; then
    # /code/block-rate-notify.sh
    chown -R monero:monero /code
    exec su-exec monero $@ --block-rate-notify "/code/block-rate-notify.sh -b%b -t%t"
    # exec su-exec monero $@ --block-rate-notify "b=%b t=%t /code/block-rate-notify.sh"
  else
    exec su-exec monero $@
  fi
fi

exec $@
