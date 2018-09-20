#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=git@github.com:bitprim/bitcore-wallet-service
[ ! -n "$BRANCH" ] && BRANCH=dev

log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}


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
apt-get update && apt-get install -y mongodb-clients


if [ ! -d "/bitprim/bws/.git" ] ; then

log "Pulling Repo data from ${CONFIG_REPO}:${BRANCH}"
git clone -b ${BRANCH} ${CONFIG_REPO} /bitprim/bws
else
log "Refreshing Repository Data from ${CONFIG_REPO}:${BRANCH}"
cd /bitprim/bws/
git checkout ${BRANCH}
git fetch --all
git reset --hard origin/${BRANCH}
git pull
fi


cd /bitprim/bws


log "Installing node depencies /bitprim/bws" 
npm install  
mv config/default.example.json /config/default.json
fi
tail -f /dev/null

