#!/bin/bash
log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}


[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git
[ ! -n "$APP_REPO" ] && APP_REPO=http://github.com/bitprim/keoken-explorer-backend
[ ! -n "$BRANCH" ] && BRANCH=master
[ ! -n "$CONAN_VERSION" ] && CONAN_VERSION=1.7.2

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


install_packages()
{
if [ ! -e /tmp/already_installed ] ; then
    apt-get update
    apt-get -y install cmake build-essential python3-pip git locales $ADDITIONAL_PACKAGES
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    locale-gen en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    pip3 install flask requests
    if [ $? -eq 0 ] ; then
        echo "$ADDITIONAL_PACKAGES installed" >/tmp/already_installed
    fi
fi
}





_term() {
  log "Caught SIGTERM signal!"
  log "Waiting for $child"
  kill -TERM "$child" ; wait $child 2>/dev/null
}



start_keoken_backend()
{
cd /bitprim/keoken-backend
trap _term SIGTERM

./configure.sh
python3 backend.py
}




### WORK Starts Here
shopt -s nocasematch
clone_repos
start_keoken_backend
sleep 300
