#!/usr/bin/with-contenv bashio

set -e

bashio::log.info "Cloudflare DDNS a iniciar..."

# Ler configuração do Home Assistant
export CLOUDFLARE_API_TOKEN="$(bashio::config 'cloudflare_api_token')"
export IP4_DOMAINS="$(bashio::config 'ip4_domains')"
export PROXIED="$(bashio::config 'proxied')"
export IP4_PROVIDER="$(bashio::config 'ip4_provider')"
export IP6_PROVIDER="$(bashio::config 'ip6_provider')"
export UPDATE_CRON="$(bashio::config 'update_cron')"
export UPDATE_ON_START="$(bashio::config 'update_on_start')"
export TTL="$(bashio::config 'ttl')"
export DELETE_ON_STOP="$(bashio::config 'delete_on_stop')"
export DELETE_ON_FAILURE="$(bashio::config 'delete_on_failure')"
export EMOJI="$(bashio::config 'emoji')"

bashio::log.info "Domínios: ${IP4_DOMAINS}"
bashio::log.info "Proxy: ${PROXIED}"
bashio::log.info "Intervalo: ${UPDATE_CRON}"
bashio::log.info "IPv4 provider: ${IP4_PROVIDER}"
bashio::log.info "IPv6 provider: ${IP6_PROVIDER}"

# Procurar o executável dentro da imagem oficial
CLOUDFLARE_DDNS=""

for binary in \
    /cloudflare-ddns \
    /app/cloudflare-ddns \
    /usr/local/bin/cloudflare-ddns \
    /usr/bin/cloudflare-ddns
do
    if [ -x "$binary" ]; then
        CLOUDFLARE_DDNS="$binary"
        break
    fi
done

# Se não encontrou pelo caminho conhecido, procurar
if [ -z "$CLOUDFLARE_DDNS" ]; then
    CLOUDFLARE_DDNS="$(find / -type f -name 'cloudflare-ddns' -perm -111 2>/dev/null | head -n 1 || true)"
fi

if [ -z "$CLOUDFLARE_DDNS" ]; then
    bashio::log.error "Não foi possível encontrar o executável cloudflare-ddns na imagem."
    exit 1
fi

bashio::log.info "Executável encontrado em: ${CLOUDFLARE_DDNS}"

exec "$CLOUDFLARE_DDNS"
