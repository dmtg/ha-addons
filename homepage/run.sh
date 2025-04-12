#!/bin/sh

# Recolhe variáveis do ficheiro /data/options.json
PORT=$(jq -r '.port' /data/options.json)
HOSTNAME=$(jq -r '.custom_hostname' /data/options.json)
ALLOWED_HOSTS=$(jq -r '.HOMEPAGE_ALLOWED_HOSTS' /data/options.json)

# Define paths for Homepage's data
HOMEPAGE_CONFIG_PATH="/app/config"
PERSISTENT_CONFIG_PATH="/share/homepage/configs"

# Garante que o diretório existe
mkdir -p $PERSISTENT_CONFIG_PATH

# Copia configs persistentes ao iniciar
cp -R $PERSISTENT_CONFIG_PATH/* $HOMEPAGE_CONFIG_PATH/ 2>/dev/null

# Sincronização em background
sync_to_persistent() {
    while true; do
        cp -R $HOMEPAGE_CONFIG_PATH/* $PERSISTENT_CONFIG_PATH/ 2>/dev/null
        sleep 60
    done
}
sync_to_persistent &

# Exporta as variáveis de ambiente
echo "Exporting hostname..."
export NEXTAUTH_URL_INTERNAL="http://$HOSTNAME:$PORT"
export HOMEPAGE_ALLOWED_HOSTS="$ALLOWED_HOSTS"

# Inicia o servidor
echo "Starting production server..."
node /app/server.js & PID=$!

# Espera pelo processo
wait $PID
