#!/bin/bash
#HTTP_ADDR=http://172.17.0.1
OUTPUT_FILE=/bitprim/conf/bitprim-node.cfg
#OUTPUT_FILE=./bitprim-node.cfg
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git
NODE_NAME="bitcore-${COIN}-${NETWORK}"
IS_TESTNET=0
BITCORE_NETWORK=livenet

if [ "$NETWORK" == "testnet" ] ; then
IS_TESTNET=1
BITCORE_NETWORK=testnet
fi


configure_bitcoinabc()
{
add-apt-repository ppa:bitcoin-abc/ppa && apt-get update && apt-get -y install bitcoind 

cat <<EOF >/root/.bitcoin/bitcoin.conf
debug=1
testnet=${IS_TESTNET}
server=1
whitelist=127.0.0.1
# reindex=1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubhashblock=tcp://127.0.0.1:28332
rpcallowip=127.0.0.1
rpcuser=bitcoin
rpcpassword=local321
uacomment=bitcore
# testnet=1
# connect=104.198.194.166
# uahfstarttime=1500500000
# uahfstarttime=1500920000
# uahfstarttime=1501262000
# connect=104.198.194.166
EOF

}



configure_node()
{
cd /root/.bitcoin
bitcore create ${NODE_NAME} && bitcore uninstall address && bitcore uninstall db && bitcore install insight-api && bitcore install insight-ui

BITCOIND_BINARY=$(cat bitcore-node.json | jq '.servicesConfig.bitcoind.spawn.exec' -r)
BITCOIND_DATADIR=$(cat bitcore-node.json | jq '.servicesConfig.bitcoind.spawn.datadir' -r)

if [ "${COIN}" == "bcc" ] ; then
BITCOIND_BINARY="/usr/bin/bitcoind"
BITCOIND_DATADIR="/root/.bitcoin"
configure_bitcoinabc
fi

cd /root/blockdozer-insight
copy -R * /root/.bitcoin/bitcore-${NODE_NAME}/node_modules/insight-ui


cd /root/.bitcoin/${NODE_NAME}

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
      "disableRateLimiter": true
    }
  }
}
EOF

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
bitcore start &
child=$!
wait $child
}

### WORK Starts Here

configure_node
start_bitcore
