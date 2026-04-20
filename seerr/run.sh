#!/usr/bin/with-contenv bashio

CONFIG_PATH="/share/seerr/configs"

mkdir -p "$CONFIG_PATH"

# Permissões para o user do Seerr (node = 1000)
chown -R 1000:1000 "$CONFIG_PATH"
chmod -R 775 "$CONFIG_PATH"

# Substituir config interna
rm -rf /app/config
ln -s "$CONFIG_PATH" /app/config

echo "Starting Seerr using config at $CONFIG_PATH"

exec /app/seerr
