#!/bin/sh
# Railway injects $PORT at runtime (default 8080). Substitute it into the
# nginx config before starting, so the healthcheck can reach the server.
: "${PORT:=80}"
sed -i "s/__PORT__/${PORT}/g" /etc/nginx/conf.d/default.conf
exec nginx -g 'daemon off;'
