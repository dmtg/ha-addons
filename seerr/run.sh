#!/bin/sh

CONFIG_PATH="/share/seerr/configs"

# garantir estrutura mínima
mkdir -p "$CONFIG_PATH/logs"

# ligar config
rm -rf /app/config
ln -s "$CONFIG_PATH" /app/config

echo "Starting Seerr..."

exec node dist/index.js
