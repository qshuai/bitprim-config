#!/bin/bash
log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}


[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git
[ ! -n "$APP_REPO" ] && APP_REPO=https://github.com/bitprim/bitprim-insight
[ ! -n "$ENTRYPOINT_SCRIPT" ] && ENTRYPOINT_SCRIPT=entrypoint-restapi-new.sh
[ ! -n "$BRANCH" ] && BRANCH=master
[ ! -n "$CONAN_VERSION" ] && CONAN_VERSION=1.3.3
[ ! -n "$DOTNET_VERSION" ] && DOTNET_VERSION=2.0

export GIT_DISCOVERY_ACROSS_FILESYSTEM=1



clone_repos()
{


if [ -d "/bitprim/bitprim-config/.git" ] ; then
log "Refreshing $CONFIG_REPO Files on /bitprim/bitprim-config"
cd /bitprim/bitprim-config && git pull
else
log "Cloning $CONFIG_REPO to /bitrpim/bitprim-config"
git clone ${CONFIG_REPO} /bitprim/bitprim-config
fi



if [ -d "/bitprim/bitprim-insight/.git" ] ; then
log "Refreshing $APP_REPO Files on /bitprim/bitprim-insight"
cd /bitprim/bitprim-insight 
git fetch --all
git checkout ${BRANCH}
git reset --hard ${BRANCH}
git pull
else
log "Cloning $APP_REPO to /bitrpim/bitprim-insight"
git clone ${APP_REPO} -b ${BRANCH} /bitprim/bitprim-insight
fi
[ ! -n "$API_VERSION" ] && API_VERSION="${BRANCH}-$(git rev-parse --short HEAD)"
log "API_VERSION set to ${API_VERSION}"
}

install_packages()
{
if [ ! -e /tmp/already_installed ] ; then
    apt-get update
    apt-get -y install cmake build-essential python-pip git locales $ADDITIONAL_PACKAGES
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    locale-gen en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    apt-get -y remove python-pip
    easy_install pip && pip install conan==${CONAN_VERSION} cpuid &&  conan remote add bitprim https://api.bintray.com/conan/bitprim/bitprim
    if [ $? -eq 0 ] ; then
        echo "$ADDITIONAL_PACKAGES installed" >/tmp/already_installed
    fi
fi
}





copy_config()
{
cd /bitprim


if [ -n "$APP_CONFIG_FILE" ] ; then
log "Copying REST API App  Config ${APP_CONFIG_FILE} from repo (CONFIG_FILE variable found)"
cp -rf bitprim-config/$APP_CONFIG_FILE /bitprim/bitprim-insight/bitprim.insight/appsettings.json

else

shopt -s nocasematch
case $FULL_NODE in
yes|y|true|1)
log "Copying default REST API Full Node config appsettings-node.json from repo"
cp -rf bitprim-config/appsettings-node.json /bitprim/bitprim-insight/bitprim.insight/appsettings.json
;;

*)
log "Copying default REST API Forwarder Node config appsettings-fwd.json from repo"
cp bitprim-config/appsettings-fwd.json /bitprim/bitprim-insight/bitprim.insight/appsettings.json
log "Configuring FORWARD_URL:$FORWARD_URL in appsettings.json"
sed -i "s#%FORWARD_URL%#${FORWARD_URL}#g" /bitprim/bitprim-insight/bitprim.insight/appsettings.json

;;
esac



log "Setting version to ${API_VERSION}"
sed -i "s#%API_VERSION%#${API_VERSION}#g" /bitprim/bitprim-insight/bitprim.insight/appsettings.json


fi

}


_term() {
  log "Caught SIGTERM signal!"
  log "Waiting for $child"
  kill -TERM "$child" ; wait $child 2>/dev/null
}



start_bitprim()
{
cd /bitprim/bitprim-insight/bitprim.insight
trap _term SIGTERM

if [ -e "$DB_DIR/exclusive_lock" ] ; then
log "Removing exclusive_lock file"
rm -f $DB_DIR/exclusive_lock
fi


log "Cleaning Conan cache"
conan remove --force '*'
conan remote remove conan-center
conan remote remove conan-transit
log "Starting Build"
rm -f build_complete && dotnet build /property:Platform=x64 /p:${COIN^^}=true -c Release -f netcoreapp${DOTNET_VERSION} -v normal && touch build_complete && log "Executed build successfully" && tail -f /dev/null &
wait $child

}




### WORK Starts Here
shopt -s nocasematch
install_packages
clone_repos
copy_config
start_bitprim
sleep 20000
