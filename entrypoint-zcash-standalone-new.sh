#!/bin/bash
OUTPUT_FILE=/bitprim/conf/bitprim-node.cfg
NODE_MEMORY_LIMIT=8192
NODE_NAME="bitcore-${COIN}-${NETWORK}"
IS_TESTNET=0
BITCORE_NETWORK=livenet

if [ "$NETWORK" == "testnet" ] ; then
IS_TESTNET=1
BITCORE_NETWORK=testnet
fi


if [ -d /root/.bitcoin/${NODE_NAME} ] ; then
echo "Cleaning old bitcore node"
rm -rf /root/.bitcoin/${NODE_NAME}
fi




configure_node()
{
        echo "Creating Node ${NODE_NAME}"
        cd /root/.bitcoin
        bitcore create ${NODE_NAME} && cd ${NODE_NAME} && bitcore uninstall address && bitcore uninstall db && bitcore install insight-api && bitcore install insight-ui
        BITCOIND_BINARY=$(cat bitcore-node.json | jq '.servicesConfig.bitcoind.spawn.exec' -r)
        BITCOIND_DATADIR=/root/.bitcoin/blockchain
        if [ "${COIN}" == "bcc" ] ; then
            BITCOIND_BINARY="/usr/bin/bitcoind"
        fi #[ "${COIN}" == "bcc" ]
    cd /root/.bitcoin/${NODE_NAME}
    if [ "${STANDALONE}" == "true" ] ; then
    echo "Creating bitcore-node.json for standalone bitcore node"
    REMOTE_BITCOIND="bdz-load-balancer.blockdozer" 
    cat <<EOF >bitcore-node.json
{
  "network": "${BITCORE_NETWORK}",
  "port": 3001,
  "services": [
    "bitcoind",
    "insight-api",
    "insight-ui",
    "web"
  ],
  "servicesConfig": {
    "bitcoind": {
      "connect": [{
        "rpcuser": "bitcoin",
        "rpcpassword": "local321",
        "rpchost": "${REMOTE_BITCOIND}",
        "zmqpubrawtx" : "tcp://${REMOTE_BITCOIND}:28332",
        "zmqpubhashblock": "tcp://${REMOTE_BITCOIND}:28332"
      }]
    },
    "insight-api": {
      "disableRateLimiter": true,
      "enableCache": true
    }
  }
}
EOF
  else
    echo "Creating bitcore-node.json for full bitcore node"
    cat <<EOF >bitcore-node.json
{
  "network": "${BITCORE_NETWORK}",
  "port": 3001,
  "services": [
    "bitcoind",
    "insight-api",
    "insight-ui",
    "web"
  ],
  "servicesConfig": {
    "bitcoind": {

      "spawn": {
        "datadir": "${BITCOIND_DATADIR}",
        "exec": "${BITCOIND_BINARY}"
      }
    },
    "insight-api": {
      "disableRateLimiter": true,
      "enableCache": true
    }
  }
}
EOF

[ "${COIN}" == "bcc" ] && configure_bitcoinabc
fi #IF STANDALONE

echo "Copying UI files"
tar xpvzf /root/bitprim-config/blockdozer/insight-ui-${COIN}.tar.gz -C /root/.bitcoin/${NODE_NAME}/node_modules



if [ "${COIN}" == "bcc" ] ; then
echo "Applying patches to bitcore"
cd /root/bitprim-config/blockdozer/patches && cp -r * /root/.bitcoin/${NODE_NAME}
cp ../bitcoind /usr/bin/bitcoind
fi

cd /root/.bitcoin

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
cd /root/.bitcoin/${NODE_NAME}
node --max-old-space-size=${NODE_MEMORY_LIMIT} /usr/bin/bitcore start & child=$! | tee 
#bitcore start >/dev/console &
child=$!
wait $child
}

### WORK Starts Here

configure_node
configure_domain
start_bitcore
