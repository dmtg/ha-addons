#!/bin/sh

echo "🔧 A preparar a configuração persistente do Wizarr..."

mkdir -p /share/wizarr/configs

if [ -d /data ]; then
    cp -a /data/. /share/wizarr/configs/
fi

echo "✅ Configuração copiada."

if [ -f /app/server.js ]; then
    echo "🚀 A iniciar Wizarr através de /app/server.js..."
    exec node /app/server.js
fi

echo "❌ /app/server.js não existe."
exit 1
