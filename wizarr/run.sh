#!/bin/sh

echo "🔧 A preparar a configuração persistente do Wizarr..."

mkdir -p /share/wizarr/configs

if [ -d /data ]; then
    cp -a /data/. /share/wizarr/configs/
fi

echo "✅ Configuração copiada."

echo "🔎 A procurar o ficheiro que inicia o Wizarr..."

find / -type f \( -name "run.py" -o -name "app.py" -o -name "main.py" -o -name "wsgi.py" \) 2>/dev/null

exit 1
