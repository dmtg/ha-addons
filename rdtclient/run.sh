#!/bin/sh

# Define paths for Homepage's data
RDTCLIENT_CONFIG_PATH="/app"
RDTCLIENT_DATA_PATH="/downloads"
# Mapped directories from the host
PERSISTENT_CONFIG_PATH="/share/rdtclient"
PERSISTENT_DATA_PATH="/share/rdtclient/downloads"
# Ensure the persistent directories exist
mkdir -p $PERSISTENT_CONFIG_PATH
mkdir -p $PERSISTENT_DATA_PATH

# Function to sync data from Homepage's directories to persistent storage
sync_to_persistent() {
    while true; do
        cp -R $RDTCLIENT_CONFIG_PATH/* $PERSISTENT_CONFIG_PATH/ 2>/dev/null
        cp -R $RDTCLIENT_DATA_PATH/* $PERSISTENT_DATA_PATH/ 2>/dev/null
        sleep 60  # Sync every 60 seconds, adjust as needed
    done
}

# Sync data to Homepage's directories on startup
cp -R $PERSISTENT_CONFIG_PATH/* $RDTCLIENT_CONFIG_PATH/ 2>/dev/null
cp -R $PERSISTENT_DATA_PATH/* $RDTCLIENT_DATA_PATH/ 2>/dev/null
# Start continuous sync in the background
sync_to_persistent &

# Exporting hostname
echo "Exporting hostname..."
export NEXTAUTH_URL_INTERNAL="http://$HOSTNAME:${PORT:-6500}"

# Migrating database
#echo "Migrating database..."
#cd ./migrate; yarn db:migrate & PID=$!

# Wait for migration to finish
#wait $PID

# Check and copy default.json if necessary
#cp -n /app/config/default.json /app/data/config/default.json

# Starting Homepage
#echo "Starting production server..."
#node /app/index.js & PID=$!

# Wait for Homarr server process to end
wait $PID
