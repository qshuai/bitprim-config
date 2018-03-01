#!/bin/bash
OUTPUT_FILE=/bitprim/conf/bitprim-node.cfg
NODE_MEMORY_LIMIT=8192
NODE_NAME="bitcore-${NETWORK}"
IS_TESTNET=0
BITCORE_NETWORK=livenet

if [ "$NETWORK" == "testnet" ] ; then
IS_TESTNET=1
BITCORE_NETWORK=testnet
fi


if [ -d /root/.zcash/${NODE_NAME} ] ; then
echo "Cleaning old bitcore node"
rm -rf /root/.zcash/${NODE_NAME}
fi


configure_node()
{
    echo "Creating Node ${NODE_NAME}"
    cd /root/.zcash
    zcash-bitcore-node create ${NODE_NAME} && cd ${NODE_NAME} && zcash-bitcore-node install https://github.com/BitMEX/zcash-insight-api
    cd /root/.zcash/${NODE_NAME}
    if [ "${STANDALONE}" == "true" ] ; then
    echo "Creating bitcore-node.json for standalone bitcore node ${REMOTE_BITCOIND_HOST}"
[ ! -n "${REMOTE_BITCOIND_HOST}" ] && REMOTE_BITCOIND_HOST="bdz-lb.bdz-test" 
[ ! -n "${REMOTE_BITCOIND_ZMQPORT}" ] && REMOTE_BITCOIND_ZMQPORT="28442"
[ ! -n "${REMOTE_BITCOIND_PORT}" ] && REMOTE_BITCOIND_PORT="8442"

cat <<EOF >bitcore-node.json
{
  "network": "${BITCORE_NETWORK}",
  "port": 3001,
  "services": [
    "bitcoind",
    "zcash-insight-api",
    "web"
  ],
  "servicesConfig": {
    "bitcoind": {
      "connect": [{
        "rpcuser": "bitcoin",
        "rpcpassword": "local321",
        "rpcport": "${REMOTE_BITCOIND_PORT}",
        "rpchost": "${REMOTE_BITCOIND_HOST}",
        "zmqpubrawtx" : "tcp://${REMOTE_BITCOIND_HOST}:${REMOTE_BITCOIND_PORT}",
        "zmqpubhashblock": "tcp://${REMOTE_BITCOIND_HOST}:${REMOTE_BITCOIND_PORT}"
      }]
    },
    "zcash-insight-api": {
      "disableRateLimiter": true,
      "enableCache": true
    }
  }
}
EOF
fi #IF STANDALONE
}

_term() {
  echo "Caught SIGTERM signal!"
  echo Waiting for $child
  kill -TERM "$child" ; wait $child 2>/dev/null
}

start_bitcore()
{
trap _term SIGTERM
echo "Starting Bitcore"
cd /root/.zcash/${NODE_NAME}
node --max-old-space-size=${NODE_MEMORY_LIMIT} /usr/bin/zcash-bitcore-node start & child=$! | tee  
#bitcore start >/dev/console &
child=$!
wait $child
}

### WORK Starts Here

configure_node
start_bitcore
