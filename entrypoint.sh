#!/bin/bash
HTTP_ADDR=http://172.17.0.1
OUTPUT_FILE=/bitprim/conf/bitprim-node.cfg
#OUTPUT_FILE=./bitprim-node.cfg

if [ -n "$CONFIG_FILE" ] ; then
echo "Downloading $HTTP_ADDR/${CONFIG_FILE} (CONFIG_FILE variable found)"
curl -so ${OUTPUT_FILE}  ${HTTP_ADDR}/${CONFIG_FILE}
else
[ ! -n "$COIN" ] && COIN=btc
[ ! -n "$NETWORK" ] && NETWORK=mainnet
echo "Downloading $HTTP_ADDR/bitprim-node-${COIN}-${NETWORK}.cfg"
curl -so ${OUTPUT_FILE} ${HTTP_ADDR}/bitprim-node-${COIN}-${NETWORK}.cfg
fi

DB_DIR=$(sed -nr "/^\[database\]/ { :l /^directory[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $OUTPUT_FILE)

find_external_port()
{

[ "$NETWORK" == "testnet" ] && PORT=18333 || PORT=8333

for portmap in $(curl -s http://rancher-metadata/latest/self/container/ports)
do
    MAPPED_PORT_LINE=$(curl -s http://rancher-metadata/latest/self/container/ports/${portmap} | grep ":${PORT}")
    if [ -n "${MAPPED_PORT_LINE}" ]
    then
        MAPPED_PORT=$(echo ${MAPPED_PORT_LINE} | cut -d: -f2)
        break
    fi
done
}

find_external_port

EXTERNAL_IP=$(curl http://rancher-metadata/latest/self/host/agent_ip)
echo $EXTERNAL_IP:$MAPPED_PORT

sed -i "s/self =.*/self = ${EXTERNAL_IP}:${MAPPED_PORT}/g" /bitprim/conf/bitprim-node.cfg


if [ ! -d "${DB_DIR}" ] ; then echo "Initializing database directory"
/bitprim/bin/bn -c $OUTPUT_FILE -i
/bitprim/bin/bn -c $OUTPUT_FILE
else
/bitprim/bin/bn -c $OUTPUT_FILE
fi
