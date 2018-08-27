#!/bin/bash
#HTTP_ADDR=http://172.17.0.1
OUTPUT_FILE=/bitprim/conf/bitprim-restapi.cfg
#OUTPUT_FILE=./bitprim-node.cfg
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git
[ ! -n "$DOTNET_VERSION" ] && DOTNET_VERSION=2.0


log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}



install_packages()
{
if [ ! -e /tmp/already_installed ] ; then
    apt-get update
    apt-get -y install git $ADDITIONAL_PACKAGES 
    if [ $? -eq 0 ] ; then
	echo "$ADDITIONAL_PACKAGES installed" >/tmp/already_installed
    fi
fi
}


clone_repo()
{
if [ -d "/bitprim/bitprim-config/.git" ] ; then
log "Refreshing $CONFIG_REPO Files on /bitprim/bitprim-config"
cd /bitprim/bitprim-config && git pull
else
log "Cloning $CONFIG_REPO to /bitrpim/bitprim-config"
git clone ${CONFIG_REPO} /bitprim/bitprim-config
fi
}


copy_config()
{
cd /bitprim 
mkdir -p /bitprim/{conf,log,database,bin}
if [ -n "$CONFIG_FILE" ] ; then
log "Copying Bitprim Node Config ${CONFIG_FILE} from repo (CONFIG_FILE variable found)"
cp bitprim-config/$CONFIG_FILE ${OUTPUT_FILE}

else
[ ! -n "$COIN" ] && COIN=bch
[ ! -n "$NETWORK" ] && NETWORK=mainnet
log "Copying default Bitprim Node config bitprim-restapi-${COIN}-${NETWORK}.cfg from repo"
cp bitprim-config/bitprim-restapi-${COIN}-${NETWORK}.cfg  ${OUTPUT_FILE}
fi

DB_DIR=$(sed -nr "/^\[database\]/ { :l /^directory[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $OUTPUT_FILE)

}

clean_db_directory()
{
if [ -d "${DB_DIR}" ] ; then
  if [ ! -e /tmp/cleaned_db_directory ] ; then
  echo "Cleaning up database directory"
  rm -rf "${DB_DIR:?}"/* && rmdir "$DB_DIR"
  [ $? -eq 0 ] && touch /tmp/cleaned_db_directory
  fi
fi


}

_term() {
  echo "Caught SIGTERM signal!"
  echo "Waiting for $child"
  kill -TERM "$child" ; wait $child 2>/dev/null
}

start_bitprim()
{
ulimit -c 100000
log "Ulimit set to: $(ulimit -c)"
cd /bitprim/bitprim-insight/bitprim.insight
log "Starting REST-API Node"
trap _term SIGTERM

if [ -n "$NEW_DIR_STRUCTURE" ] ; then
i=$((${#HOSTNAME}-1))
NODE_INDEX="-${HOSTNAME:$i:1}"
NEW_DB_DIR=${DB_DIR}${NODE_INDEX}
f=$((${#DB_DIR}-2))
DBDIR_SUFFIX=${DB_DIR:$f:2}
if [ "${DBDIR_SUFFIX}" != "${NODE_INDEX}" ]
then
  log "Replacing database directory $DB_DIR with $NEW_DB_DIR in config file $OUTPUT_FILE"
  sed -i "s#${DB_DIR}#${NEW_DB_DIR}#g" $OUTPUT_FILE
  DB_DIR=${NEW_DB_DIR}
else
  log "Database Directory already set to $NEW_DB_DIR in config file $OUTPUT_FILE"
fi
fi



if [ -e "$DB_DIR/exclusive_lock" ] ; then
echo "Removing exclusive_lock file"
if [ -e "$DB_DIR/flush_lock" ] ; then
  log "Flush_lock was found!, trying restoring DB from snapshot"
  if [ -d "$DB_DIR/../database-snapshot" ] ; then
    log "Cleaning up database directory $DB_DIR"
    rm -rf $DB_DIR/*
    log "Restoring database from database snaphost"
    cp -R --reflink $DB_DIR/../database-snapshot/* $DB_DIR
  else
    log "Running with corrupted database, please restore snapshot manually"
  fi
rm -f $DB_DIR/*_lock
fi





log "Starting REST-API"
if [ -e /bitprim/bitprim-insight/bitprim.insight/build_complete ] ; then
dotnet bin/x64/Release/netcoreapp${DOTNET_VERSION}/bitprim.insight.dll --server.port="$SERVER_PORT" --server.address=0.0.0.0 &
child=$!
log "Started dotnet process PID=$child"
wait $child
else
log "build_complete flag not present, sleeping for 10 seconds and retrying "
sleep 10
start_bitprim
fi
}

### WORK Starts Here
shopt -s nocasematch
install_packages
clone_repo
copy_config
case "$CLEAN_DB_DIRECTORY" in
yes|y|true|1)
echo "Cleaning DB Directory before starting node"
clean_db_directory
;;
esac
[ "$CLEAN_DB_DIRECTORY" == "true" ] && clean_db_directory
start_bitprim
sleep 120