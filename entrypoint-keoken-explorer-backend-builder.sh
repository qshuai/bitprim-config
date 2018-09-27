#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && APP_REPO=https://github.com/bitprim/keoken-explorer-backend
[ ! -n "$BRANCH" ] && BRANCH=master

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

