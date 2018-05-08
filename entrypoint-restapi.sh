#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git
[ ! -n "$APP_REPO" ] && APP_REPO=https://github.com/bitprim/bitprim-insight
[ ! -n "$ENTRYPOINT_SCRIPT" ] && ENTRYPOINT_SCRIPT=entrypoint-restapi-new.sh
apt-get update && apt-get install -y git
mkdir -p /bitprim/{conf,log,database,bin}
echo "Cloning Config Repository ${CONFIG_REPO}"
rm -rf bitprim-config
git clone ${CONFIG_REPO} /bitprim/bitprim-config

git clone ${APP_REPO} /bitprim/bitprim-insight

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



