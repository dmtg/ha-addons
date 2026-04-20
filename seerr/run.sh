#!/bin/sh

CONFIG_PATH="/share/seerr/configs"

echo "Fixing permissions..."

# correr como root primeiro
mkdir -p "$CONFIG_PATH"
chmod -R 777 /share

# criar estrutura esperada pelo Seerr
mkdir -p "$CONFIG_PATH/logs"

# limpar config interna e ligar ao share
rm -rf /app/config
ln -s "$CONFIG_PATH" /app/config

echo "Starting Seerr..."

# correr como user node (UID 1000)
exec su-exec 1000:1000 node dist/index.js
