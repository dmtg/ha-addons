#!/usr/bin/with-contenv bashio
set -e

CLOUDFLARE_API_TOKEN="$(bashio::config 'cloudflare_api_token')"
IP4_DOMAINS="$(bashio::config 'ip4_domains')"
PROXIED="$(bashio::config 'proxied')"
IP4_PROVIDER="$(bashio::config 'ip4_provider')"
IP6_PROVIDER="$(bashio::config 'ip6_provider')"
UPDATE_CRON="$(bashio::config 'update_cron')"
UPDATE_ON_START="$(bashio::config 'update_on_start')"
TTL="$(bashio::config 'ttl')"
DELETE_ON_STOP="$(bashio::config 'delete_on_stop')"
DELETE_ON_FAILURE="$(bashio::config 'delete_on_failure')"
EMOJI="$(bashio::config 'emoji')"

# Valores por defeito caso o Home Assistant devolva null/vazio
if [ -z "$PROXIED" ] || [ "$PROXIED" = "null" ]; then
    PROXIED='is(micro.xavelha.top) || is(canico.xavelha.top)'
fi

if [ -z "$UPDATE_CRON" ] || [ "$UPDATE_CRON" = "null" ]; then
    UPDATE_CRON='@every 5m'
fi

if [ -z "$IP4_PROVIDER" ] || [ "$IP4_PROVIDER" = "null" ]; then
    IP4_PROVIDER='cloudflare.trace'
fi

if [ -z "$IP6_PROVIDER" ] || [ "$IP6_PROVIDER" = "null" ]; then
    IP6_PROVIDER='none'
fi

if [ -z "$TTL" ] || [ "$TTL" = "null" ]; then
    TTL='1'
fi

if [ -z "$UPDATE_ON_START" ] || [ "$UPDATE_ON_START" = "null" ]; then
    UPDATE_ON_START='true'
fi

if [ -z "$DELETE_ON_STOP" ] || [ "$DELETE_ON_STOP" = "null" ]; then
    DELETE_ON_STOP='false'
fi

if [ -z "$DELETE_ON_FAILURE" ] || [ "$DELETE_ON_FAILURE" = "null" ]; then
    DELETE_ON_FAILURE='false'
fi

if [ -z "$EMOJI" ] || [ "$EMOJI" = "null" ]; then
    EMOJI='true'
fi

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    bashio::log.error "O Cloudflare API Token não está configurado."
    exit 1
fi

if [ -z "$IP4_DOMAINS" ]; then
    bashio::log.error "Nenhum domínio IPv4 foi configurado."
    exit 1
fi

# Exportar variáveis para o Cloudflare DDNS
export CLOUDFLARE_API_TOKEN
export IP4_DOMAINS
export PROXIED
export IP4_PROVIDER
export IP6_PROVIDER
export UPDATE_CRON
export UPDATE_ON_START
export TTL
export DELETE_ON_STOP
export DELETE_ON_FAILURE
export EMOJI

bashio::log.info "Cloudflare DDNS iniciado."
bashio::log.info "Domínios: ${IP4_DOMAINS}"
bashio::log.info "Proxy: ${PROXIED}"
bashio::log.info "Intervalo: ${UPDATE_CRON}"
bashio::log.info "IPv4 provider: ${IP4_PROVIDER}"
bashio::log.info "IPv6 provider: ${IP6_PROVIDER}"

exec /usr/bin/cloudflare-ddns
