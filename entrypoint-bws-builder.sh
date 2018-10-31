#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=git@github.com:bitprim/bitcore-wallet-service
[ ! -n "$BRANCH" ] && BRANCH=dev

log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}

log "Removing build_complete flag"
rm -rf /bitprim/bws/build_complete

log "Setting up SSH KEY for remore repo access"
cd /root
mkdir -p /root/.ssh
echo "${SSH_KEY}" >.ssh/id_rsa
chmod 600 .ssh/id_rsa
rm -rf bitprim-config
cat <<EOF >/root/.ssh/config 
Host *
StrictHostKeyChecking no 
EOF


log "Installing MongoDB-CLient"
apt-get update && apt-get install -y mongodb-clients netcat


if [ ! -d "/bitprim/bws/.git" ] ; then

log "Pulling Repo data from ${CONFIG_REPO}:${BRANCH}"
git clone -b ${BRANCH} ${CONFIG_REPO} /bitprim/bws
else
log "Refreshing Repository Data from ${CONFIG_REPO}:${BRANCH}"
cd /bitprim/bws/
git checkout ${BRANCH}
git fetch --all
git checkout ${BRANCH}
git reset --hard origin/${BRANCH}
git pull
fi


cd /bitprim/bws


log "Installing node depencies /bitprim/bws" 
npm install && touch build_complete
mv config/default.example.json config/default.json
[ -n "${BTC_MAINNET_EXPLORER_URL}" ] && log "Setting MainnetBTC explorer to ${BCH_MAINNET_EXPLORER_URL}"&& sed -i "s#https://btc.blockdozer.com#${BTC_MAINNET_EXPLORER_URL}#g" config/default.json
[ -n "${BTC_TESTNET_EXPLORER_URL}" ] && log "Setting TestnetBTC explorer to ${BTC_TESTNET_EXPLORER_URL}"&& sed -i "s#https://tbtc.blockdozer.com#${BTC_TESTNET_EXPLORER_URL}#g" config/default.json
[ -n "${BCH_MAINNET_EXPLORER_URL}" ] && log "Setting MainnetBCH explorer to ${BCH_MAINNNET_EXPLORER_URL}"&& sed -i "s#https://blockdozer.com#${BCH_MAINNET_EXPLORER_URL}#g" config/default.json
[ -n "${BCH_TESTNET_EXPLORER_URL}" ] && log "Setting TestnetBCH explorer to ${BCH_TESTNET_EXPLORER_URL}" && sed -i "s#https://tbch.blockdozer.com#${BCH_TESTNET_EXPLORER_URL}#g" config/default.json
[ -n "${GOOGLE_FCM_KEY}" ] && log "Setting Google Firebase Key in config.js" && sed -i "s#AAAAAAAAAAAAgooglekey${GOOGLE_FCM_KEY}#g" config.js

nc -lvp 9999

