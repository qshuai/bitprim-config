#!/bin/bash
[ ! -n "$APP_REPO" ] && APP_REPO=git@github.com:bitprim/keoken-explorer-backend.git
[ ! -n "$BRANCH" ] && BRANCH=master


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



log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}


if [ ! -d "/bitprim/keoken-backend/.git" ] ; then

log "Pulling Repo data from ${APP_REPO}:${BRANCH}"
git clone -b ${BRANCH} ${APP_REPO} /bitprim/keoken-backend
else
log "Refreshing Repository Data from ${APP_REPO}:${BRANCH}"
cd /bitprim/keoken-backend
git checkout ${BRANCH}
git fetch --all
git reset --hard origin/${BRANCH}
git pull
fi


cd /bitprim/keoken-backend
tail -f /dev/null

