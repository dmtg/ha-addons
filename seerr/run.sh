#!/usr/bin/with-contenv bashio

CONFIG_PATH="/share/seerr/configs"

mkdir -p "$CONFIG_PATH"
chown -R 1000:1000 "$CONFIG_PATH"

rm -rf /app/config
ln -s "$CONFIG_PATH" /app/config

echo "Starting Seerr..."

exec /app/seerr
