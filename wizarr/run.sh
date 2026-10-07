#!/usr/bin/env bash

echo "🔧 A preparar a configuração persistente do Wizarr..."

mkdir -p /share/wizarr/configs

# Copiar a configuração existente do Wizarr para a pasta persistente
if [ -d /data ]; then
    cp -a /data/. /share/wizarr/configs/
fi

# Garantir que o Wizarr continua a arrancar
exec /init
