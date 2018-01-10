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


if [ -d /root/.bitcoin/${NODE_NAME} ] ; then
echo "Cleaning old bitcore node"
rm -rf /root/.bitcoin/${NODE_NAME}
fi



configure_bitcoinabc()
{
echo Configuring BitcoinABC
add-apt-repository ppa:bitcoin-abc/ppa && apt-get update && apt-get -y install bitcoind 
mv /usr/bin/bitcoind /usr/bin/bitcoind.old 
mv /usr/bin/bitcoind.new /usr/bin/bitcoind
cat <<EOF >/root/.bitcoin/bitcoin.conf
debug=1
testnet=${IS_TESTNET}
datadir=/root/.bitcoin/blockchain
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
usecashaddr=0
# testnet=1
# connect=104.198.194.166
# uahfstarttime=1500500000
# uahfstarttime=1500920000
# uahfstarttime=1501262000
# connect=104.198.194.166
EOF

}

configure_domain()
{
if [ -n "$DOMAIN_NAME" ] ; then
echo "Configuring ${DOMAIN_NAME} in links.html" 
sed -i "s/blockdozer.com/$DOMAIN_NAME/g" /root/.bitcoin/${NODE_NAME}/node_modules/insight-ui/public/views/includes/links.html
fi
}


configure_node()
{
[ ! -e "/usr/bin/bitcoind" ] && configure_bitcoinabc
	echo "Creating Node ${NODE_NAME}"
	cd /root/.bitcoin
	bitcore create ${NODE_NAME} && cd ${NODE_NAME} && bitcore uninstall address && bitcore uninstall db && bitcore install insight-api && bitcore install insight-ui 
	BITCOIND_BINARY=$(cat bitcore-node.json | jq '.servicesConfig.bitcoind.spawn.exec' -r)
	BITCOIND_DATADIR=/root/.bitcoin/blockchain
        if [ "${COIN}" == "bcc" ] ; then
	    BITCOIND_BINARY="/usr/bin/bitcoind"
	fi #[ "${COIN}" == "bcc" ]
    cd /root/.bitcoin/${NODE_NAME}
    echo "Creating bitcore-node.json"
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
echo "Copying UI files"
cd /root/
echo "Cloning ${CONFIG_REPO}"
rm -rf bitprim-config 
git clone https://github.com/bitprim/bitprim-config.git
cd bitprim-config/blockdozer
tar xpvzf insight-ui-${COIN}.tar.gz -C /root/.bitcoin/${NODE_NAME}/node_modules



if [ "${COIN}" == "bcc" ] ; then
echo "Applying patches to bitcore"
cd /root/bitprim-config/blockdozer/patches
cp -r * /root/.bitcoin/${NODE_NAME}
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
bitcore start &
child=$!
wait $child
}

### WORK Starts Here

configure_node
configure_domain
start_bitcore
