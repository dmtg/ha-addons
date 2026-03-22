#!/bin/sh

echo "Starting Wizarr..."

export NEXTAUTH_URL_INTERNAL="http://$HOSTNAME:${PORT:-5690}"

exec node /app/server.js
