#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=git@github.com:bitprim/keoken-explorer.git
[ ! -n "$BRANCH" ] && BRANCH=master

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


log "Installing GIT"
apt-get update && apt-get install -y git

log "Installing NVM" 
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
. /root/.bashrc
log "Installing Node.js version 6"
nvm install 8


if [ ! -d "/bitprim/blockdozer/.git" ] ; then

log "Pulling Repo data from ${CONFIG_REPO}:${BRANCH}"
git clone -b ${BRANCH} ${CONFIG_REPO} /bitprim/keoken-explorer-frontend
else
log "Refreshing Repository Data from ${CONFIG_REPO}:${BRANCH}"
cd /bitprim/keoken-explorer-frontend/
git checkout ${BRANCH}
git fetch --all
git reset --hard origin/${BRANCH}
git pull
fi


cd /bitprim/keoken-explorer-frontend


log "Installing grunt on /bitprim/blockdozer/insight-ui" 
#npm install "grunt" "grunt-cli" "grunt-css" "grunt-markdown" "grunt-macreload" "grunt-angular-gettext"  "grunt-contrib-uglify" "grunt-contrib-concat" "grunt-contrib-watch" "grunt-replace"
npm install 
npm build:prod
fi


tail -f /dev/null

