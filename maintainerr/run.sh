#!/usr/bin/with-contenv sh

mkdir -p /opt/data
export NEXTAUTH_URL_INTERNAL="http://$HOSTNAME:${PORT:-6246}"

exec /init
