#!/bin/sh

# Define paths for Homepage's data
PETIO_CONFIG_PATH="/app/api/config"
PETIO_DATA_PATH="/app/logs"

# Mapped directories from the host
PERSISTENT_CONFIG_PATH="/share/petio/config"
PERSISTENT_DATA_PATH="/share/petio/logs"

# Ensure the persistent directories exist
mkdir -p $PERSISTENT_CONFIG_PATH
mkdir -p $PERSISTENT_DATA_PATH

# Function to sync data from Homepage's directories to persistent storage
sync_to_persistent() {
    while true; do
        cp -R $POSTERR_CONFIG_PATH/* $PERSISTENT_CONFIG_PATH/ 2>/dev/null
        cp -R $POSTERR_DATA_PATH/* $PERSISTENT_DATA_PATH/ 2>/dev/null
        sleep 60  # Sync every 60 seconds, adjust as needed
    done
}

# Sync data to Homepage's directories on startup
cp -R $PERSISTENT_CONFIG_PATH/* $POSTERR_CONFIG_PATH/ 2>/dev/null
cp -R $PERSISTENT_DATA_PATH/* $POSTERR_DATA_PATH/ 2>/dev/null
# Start continuous sync in the background
sync_to_persistent &

# Exporting hostname
echo "Exporting hostname..."
export NEXTAUTH_URL_INTERNAL="http://$HOSTNAME:${PORT:-7777}"

# Migrating database
#echo "Migrating database..."
#cd ./migrate; yarn db:migrate & PID=$!

# Wait for migration to finish
#wait $PID

# Check and copy default.json if necessary
#cp -n /app/config/default.json /app/data/config/default.json

# Starting Homepage
echo "Starting production server..."
node /app/index.js & PID=$!

# Wait for Homarr server process to end
wait $PID
