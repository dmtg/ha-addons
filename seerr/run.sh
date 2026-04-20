#!/bin/sh

CONFIG_PATH="/share/seerr/configs"

echo "Preparing Seerr config..."

# ⚠️ garantir tudo antes do symlink
mkdir -p /share/seerr
mkdir -p "$CONFIG_PATH"
mkdir -p "$CONFIG_PATH/logs"

# remover config interna
rm -rf /app/config

# criar ligação
ln -s "$CONFIG_PATH" /app/config

# debug opcional
echo "Config path:"
ls -l /app
ls -l "$CONFIG_PATH"

echo "Starting Seerr..."

exec node dist/index.js
