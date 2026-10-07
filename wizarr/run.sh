#!/usr/bin/with-contenv bashio

PERSISTENT="/share/wizarr/configs"
DATA="/data"

echo "[wizarr] A preparar armazenamento persistente..."

mkdir -p "$PERSISTENT"

# Se a pasta persistente estiver vazia, copiar os dados atuais
if [ -z "$(find "$PERSISTENT" -mindepth 1 -maxdepth 1 2>/dev/null | head -n 1)" ]; then
    echo "[wizarr] A copiar dados atuais para /share/wizarr/configs..."
    cp -a "$DATA"/. "$PERSISTENT"/ 2>/dev/null || true
fi

echo "[wizarr] Dados persistentes preparados."

# Remover /data original e criar ligação para a pasta persistente
if [ ! -L "$DATA" ]; then
    rm -rf "$DATA"
    ln -s "$PERSISTENT" "$DATA"
fi

echo "[wizarr] /data -> /share/wizarr/configs"

exec /init
