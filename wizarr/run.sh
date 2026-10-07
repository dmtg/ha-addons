#!/usr/bin/env sh

set -eu

PERSISTENT="/share/wizarr/configs"
DATA="/data"
ORIGINAL="/usr/local/bin/wizarr-entrypoint-original.sh"

echo "[wizarr-persist] 🚀 Preparing persistent storage..."

mkdir -p "$PERSISTENT"

if [ -z "$(find "$PERSISTENT" -mindepth 1 -maxdepth 1 2>/dev/null | head -n 1)" ]; then
    echo "[wizarr-persist] 📦 Copying existing /data to $PERSISTENT..."
    cp -a "$DATA"/. "$PERSISTENT"/ 2>/dev/null || true
else
    echo "[wizarr-persist] ✅ Persistent data already exists."
fi

if [ ! -L "$DATA" ]; then
    echo "[wizarr-persist] 🔗 Linking /data -> $PERSISTENT"

    rm -rf "$DATA"
    ln -s "$PERSISTENT" "$DATA"
fi

echo "[wizarr-persist] ✅ Persistent storage ready."

exec "$ORIGINAL" "$@"
