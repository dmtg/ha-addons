#!/usr/bin/env sh
set -eu

PERSISTENT="/share/wizarr/configs"
DATA="/data"

echo "🔧 A preparar configuração persistente do Wizarr..."

mkdir -p "$PERSISTENT"
mkdir -p "$DATA"

# Recuperar dados persistentes existentes
if [ -n "$(ls -A "$PERSISTENT" 2>/dev/null)" ]; then
    echo "📥 A recuperar dados de $PERSISTENT para $DATA..."
    cp -a "$PERSISTENT"/. "$DATA"/
fi

echo "💾 A ativar sincronização automática..."

(
    while true; do
        sleep 60
        cp -a "$DATA"/. "$PERSISTENT"/
    done
) &

echo "🚀 A iniciar Wizarr..."

exec /usr/local/bin/docker-entrypoint.sh \
    uv run --frozen --no-dev gunicorn \
    --config gunicorn.conf.py \
    --umask 007 \
    run:app
