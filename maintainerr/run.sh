#!/usr/bin/with-contenv sh

mkdir -p /opt/data
echo "Exporting hostname..."
export NEXTAUTH_URL_INTERNAL="http://$HOSTNAME:${PORT:-6246}"
echo "Starting production server..."
exec /init
