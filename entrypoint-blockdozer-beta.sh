#!/bin/bash
[ ! -n "$CONFIG_REPO" ] && CONFIG_REPO=ssh://vcs-user@git.dev.bitprim.org:2222/source/configs.git
[ ! -n "$ENTRYPOINT_SCRIPT" ] && ENTRYPOINT_SCRIPT=entrypoint-blockdozer-beta-new.sh

echo "Cloning Config Repository ${CONFIG_REPO}"
cd /root
mkdir -p /root/.ssh
echo "${SSH_KEY}" >.ssh/id_rsa
chmod 600 .ssh/id_rsa
rm -rf bitprim-config
cat >/root/.ssh/ssh_config <EOF
Host *
StrictHostKeyChecking no 
EOF

git clone ${CONFIG_REPO} bitprim-config
echo "Running entrypoint script ${ENTRYPOINT_SCRIPT}"
. /root/bitprim-config/${ENTRYPOINT_SCRIPT}
