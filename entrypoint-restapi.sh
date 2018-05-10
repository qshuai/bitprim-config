#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git
[ ! -n "$APP_REPO" ] && APP_REPO=https://github.com/bitprim/bitprim-insight
[ ! -n "$ENTRYPOINT_SCRIPT" ] && ENTRYPOINT_SCRIPT=entrypoint-restapi-new.sh
apt-get update && apt-get install -y git
mkdir -p /bitprim/{conf,log,database,bin}

if [ -d "/bitprim/bitprim-config" ] ; then
echo "Refreshing $CONFIG_REPO Files on /bitprim/bitprim-config"
cd /bitprim/bitprim-config && git pull
else
echo "Cloning $CONFIG_REPO to /bitrpim/bitprim-config"
git clone ${CONFIG_REPO} /bitprim/bitprim-config
fi


if [ -d "/bitprim/bitprim-insight" ] ; then
echo "Refreshing $APP_REPO Files on /bitprim/bitprim-insight"
cd /bitprim/bitprim-insight && git pull
else
echo "Cloning $APP_REPO to /bitrpim/bitprim-insight"
git clone ${APP_REPO} /bitprim/bitprim-insight
fi





_term() {
  echo "Caught SIGTERM signal!"
  echo "Waiting for $child"
  kill -TERM "$child" ; wait $child 2>/dev/null
}

trap _term SIGTERM


echo "Running entrypoint script ${ENTRYPOINT_SCRIPT}"
exec /bitprim/bitprim-config/${ENTRYPOINT_SCRIPT} &
child=$!
echo "Started entrypoint PID=$child"
wait $child



