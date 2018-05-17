#!/bin/bash

log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}



configure_nginx()
{
cat<<EOF | envsubst >/etc/nginx/conf.d/default.conf

    # configure the virtual host
    server {
      # replace with your domain name
      # replace this with your static Sinatra app files, root + public
      root /bitprim/blockdozer/insight-ui/public;
      listen 80;
      client_max_body_size 16M;
      keepalive_timeout 5;
      location ~ ^/(blocks|block/.*|status|address/.*|tx/.*|tx/send|block-index/.*|blocks-date/.*|messages/verify|contact_us) {
       try_files caca /index.html;
      }

    }

EOF
}

_term() {
  log "Caught SIGTERM signal!"
  log Waiting for $child
  kill -TERM "$child" ; wait $child 2>/dev/null
}

start_nginx()
{
trap _term SIGTERM
log "Starting Nginx"
nginx -g 'daemon off;' 
child=$!
log "Nginx Started PID=$child"
wait $child
}



configure_nginx
start_nginx
sleep 20000


