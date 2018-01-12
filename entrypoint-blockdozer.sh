#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=https://github.com/bitprim/bitprim-config.git
echo "Cloning Config Repository ${CONFIG_REPO}"
cd /root
rm -rf bitprim-config
git clone https://github.com/bitprim/bitprim-config.git
echo "Running new entrypoint script"
. /root/bitprim-config/entrypoint-blockdozer-new.sh
