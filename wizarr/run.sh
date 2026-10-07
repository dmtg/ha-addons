#!/usr/bin/env sh
set -eu

echo "🔧 A preparar a configuração persistente do Wizarr..."

mkdir -p /share/wizarr/configs

if [ -d /data ]; then
    cp -a /data/. /share/wizarr/configs/
fi

echo "✅ Configuração copiada."

echo "🚀 A iniciar Wizarr..."

cd /app
exec .venv/bin/python run.py
