#!/bin/bash

log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}



clean_bws()
{
log "Cleaning up PIDS directory"
[ ! -n "${PID_DIR}" ] && PID_DIR=pids
rm -rf ${PID_DIR:?}/*

}


_term() {
  echo "Caught SIGTERM signal!"
  echo Waiting for $child
  cd /bitprim/bws
  npm stop
}



start_bws()
{
trap _term SIGTERM
log "Starting bws"
cd /bitprim/bws && npm start
child=$!
log "BWS Started PID=$child"
wait $child
}

[ ! -n "${LOG_DIR}" ] && LOG_DIR=logs
[ ! -n "${PID_DIR}" ] && PID_DIR=pids
mkdir -p ${LOG_DIR} ${PID_DIR}

clean_bws
start_bws
sleep 300


