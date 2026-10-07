#!/usr/bin/env sh
set -eu

echo "🔧 A preparar a configuração persistente do Wizarr..."

mkdir -p /share/wizarr/configs

if [ -d /data ]; then
    cp -a /data/. /share/wizarr/configs/
fi

echo "✅ Configuração copiada."

echo "🚀 A iniciar Wizarr..."

exec /usr/local/bin/docker-entrypoint.sh \
    uv run --frozen --no-dev gunicorn \
    --config gunicorn.conf.py \
    --umask 007 \
    run:app
