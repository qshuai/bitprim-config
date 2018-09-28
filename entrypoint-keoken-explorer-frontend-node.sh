#!/bin/bash

log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}



_term() {
  log "Caught SIGTERM signal!"
  log Waiting for $child
  kill -TERM "$child" ; wait $child 2>/dev/null
}

start_node()
{
trap _term SIGTERM
log "Starting Application"
cd /bitprim/keoken-explorer-frontend
npm run build:prod
child=$!
log "NPM Started PID=$child"
wait $child
}



configure_nginx
start_node
sleep 300


