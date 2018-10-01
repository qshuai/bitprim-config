#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=git@github.com:bitprim/keoken-explorer.git
[ ! -n "$BRANCH" ] && BRANCH=master
[ ! -n "$NODE_MEMORY_LIMIT" ] && NODE_MEMORY_LIMIT=8192
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



if [ ! -d "/bitprim/keoken-explorer-faucet/.git" ] ; then

log "Pulling Repo data from ${CONFIG_REPO}:${BRANCH}"
git clone -b ${BRANCH} ${CONFIG_REPO} /bitprim/keoken-explorer-faucet
else
log "Refreshing Repository Data from ${CONFIG_REPO}:${BRANCH}"
cd /bitprim/keoken-explorer-faucet/
git checkout ${BRANCH}
git fetch --all
git reset --hard origin/${BRANCH}
git pull
fi


_term() {
  log "Caught SIGTERM signal!"
  log "Waiting for $child"
  kill -TERM "$child" "$monitor_child"  ; wait $child $monitor_child 2>/dev/null
  
}

cd /bitprim/keoken-explorer-faucet
./configure.sh
log "Running npm install"
npm install

trap _term SIGTERM
node --max-old-space-size=${NODE_MEMORY_LIMIT} init.js & child=$! | tee
child=$!
log "Node Faucet instance started PID=$child"
wait $child 

