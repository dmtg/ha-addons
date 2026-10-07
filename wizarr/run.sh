#!/usr/bin/env bashio

PERSISTENT="/share/wizarr/configs"

echo "[wizarr-copy] A copiar dados atuais..."

mkdir -p "$PERSISTENT"

cp -a /data/. "$PERSISTENT"/

echo "[wizarr-copy] Conteúdo copiado:"
ls -lah "$PERSISTENT"

echo "[wizarr-copy] Cópia concluída."

exec /init
