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
if [ -e /bitprim/bws/build_complete ] ; then
cd /bitprim/bws && npm start && tail -f ${LOG_DIR}/*

child=$!
log "Started dotnet process PID=$child"
wait $child
else
log "build_complete flag not present, sleeping for 10 seconds and retrying "
sleep 10
start_bws
fi


}

[ ! -n "${LOG_DIR}" ] && LOG_DIR=logs
[ ! -n "${PID_DIR}" ] && PID_DIR=pids
mkdir -p ${LOG_DIR} ${PID_DIR}

sleep 5

clean_bws
start_bws
sleep 300


