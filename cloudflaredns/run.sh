#!/usr/bin/with-contenv bash
set -e

export CLOUDFLARE_API_TOKEN="$(bashio::config 'cloudflare_api_token')"
export IP4_DOMAINS="$(bashio::config 'ip4_domains')"
export PROXIED="$(bashio::config 'proxied')"
export UPDATE_CRON="$(bashio::config 'update_cron')"
export UPDATE_ON_START="$(bashio::config 'update_on_start')"
export IP6_PROVIDER="$(bashio::config 'ip6_provider')"
export TTL="$(bashio::config 'ttl')"
export DELETE_ON_STOP="$(bashio::config 'delete_on_stop')"
export DELETE_ON_FAILURE="$(bashio::config 'delete_on_failure')"
export EMOJI="$(bashio::config 'emoji')"

exec /app/cloudflare-ddns
