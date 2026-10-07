#!/usr/bin/with-contenv bashio

PERSISTENT="/share/wizarr/configs"
DATA="/data"

echo "[wizarr] A preparar armazenamento persistente..."

mkdir -p "$PERSISTENT"

if [ -z "$(find "$PERSISTENT" -mindepth 1 -maxdepth 1 2>/dev/null | head -n 1)" ]; then
    echo "[wizarr] A copiar dados atuais para /share/wizarr/configs..."
    cp -a "$DATA"/. "$PERSISTENT"/ 2>/dev/null || true
fi

rm -rf "$DATA"
ln -s "$PERSISTENT" "$DATA"

echo "[wizarr] /data -> $PERSISTENT"

exec /init
