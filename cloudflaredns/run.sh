#!/usr/bin/with-contenv bashio
set -e

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

if [ -z "${CLOUDFLARE_API_TOKEN}" ]; then
  bashio::log.error "É necessário configurar o Cloudflare API Token."
  exit 1
fi

bashio::log.info "A iniciar Cloudflare DDNS..."
bashio::log.info "Domínios IPv4: ${IP4_DOMAINS}"
bashio::log.info "Proxy: ${PROXIED}"
bashio::log.info "Intervalo: ${UPDATE_CRON}"

exec /usr/bin/cloudflare-ddns
