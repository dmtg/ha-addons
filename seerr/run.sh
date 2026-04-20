#!/usr/bin/with-contenv bashio

CONFIG_PATH="/share/seerr/configs"

# Criar pasta se não existir
mkdir -p "$CONFIG_PATH"

# Garantir ligação ao path esperado pelo Seerr
if [ ! -e /app/config ]; then
    ln -s "$CONFIG_PATH" /app/config
fi

# Permissões (importante em HA)
chmod -R 777 "$CONFIG_PATH"

echo "Starting Seerr using config at $CONFIG_PATH"

# Arrancar Seerr
exec /app/seerr
