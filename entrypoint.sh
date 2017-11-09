#!/bin/bash
#HTTP_ADDR=http://172.17.0.1
OUTPUT_FILE=/bitprim/conf/bitprim-node.cfg
#OUTPUT_FILE=./bitprim-node.cfg
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git

configure_external_port()
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
EXTERNAL_IP=$(curl -s http://rancher-metadata/latest/self/host/agent_ip)
echo "Configuring network.self as: ${EXTERNAL_IP}:${MAPPED_PORT}"
sed -i "s/self =.*/self = ${EXTERNAL_IP}:${MAPPED_PORT}/g" /bitprim/conf/bitprim-node.cfg

}

copy_config()
{
echo "Cloning config repository $CONFIG_REPO"
cd /bitprim ; rm -rf bitprim-config
git clone ${CONFIG_REPO}


if [ -n "$CONFIG_FILE" ] ; then
echo "Copying ${CONFIG_FILE} from repo (CONFIG_FILE variable found)"
cp bitprim-config/$CONFIG_FILE ${OUTPUT_FILE}

else
[ ! -n "$COIN" ] && COIN=btc
[ ! -n "$NETWORK" ] && NETWORK=mainnet
echo "Copying bitprim-node-${COIN}-${NETWORK}.cfg from repo"
cp bitprim-config/bitprim-node-${COIN}-${NETWORK}.cfg  ${OUTPUT_FILE}
fi

DB_DIR=$(sed -nr "/^\[database\]/ { :l /^directory[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $OUTPUT_FILE)
}

start_bitprim()
{
echo "Starting $(/bitprim/bin/bn --version)"
if [ ! -d "${DB_DIR}" ] ; then echo "Initializing database directory"
/bitprim/bin/bn -c $OUTPUT_FILE -i
/bitprim/bin/bn -c $OUTPUT_FILE
else
/bitprim/bin/bn -c $OUTPUT_FILE
fi
}

copy_config
configure_external_port
start_bitprim
