#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git
[ ! -n "$APP_REPO" ] && APP_REPO=https://github.com/bitprim/bitprim-insight
[ ! -n "$ENTRYPOINT_SCRIPT" ] && ENTRYPOINT_SCRIPT=entrypoint-restapi-new.sh
apt-get update && apt-get install -y git
mkdir -p /bitprim/{conf,log,database,bin}
echo "Cloning Config Repository ${CONFIG_REPO}"
cd /root
rm -rf bitprim-config
git clone ${CONFIG_REPO} bitprim-config
git clone ${APP_REPO} /bitprim/bitprim-insight
echo "Running entrypoint script ${ENTRYPOINT_SCRIPT}"
. /root/bitprim-config/${ENTRYPOINT_SCRIPT}
sleep 20000