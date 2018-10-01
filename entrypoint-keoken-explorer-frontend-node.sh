#!/bin/bash

log()
{
echo $(date +"%Y-%m-%d %H:%M:%S") $@
}



configure_nginx()
{
cat<<EOF | envsubst >/etc/nginx/conf.d/default.conf

    server {
      root /bitprim/keoken-explorer-frontend/dist;
      listen 80;
      index index.html index.htm;
      etag on;
      client_max_body_size 16M;
      keepalive_timeout 5;
      location / {
        index index.html;
        try_files $uri /index.html;
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


