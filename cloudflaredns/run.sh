#!/usr/bin/with-contenv bashio
set -u

API_TOKEN="$(bashio::config 'cloudflare_api_token')"
DOMAINS="$(bashio::config 'ip4_domains')"
PROXIED_DOMAINS="$(bashio::config 'proxied_domains')"
INTERVAL="$(bashio::config 'update_interval')"
TTL="$(bashio::config 'ttl')"

API="https://api.cloudflare.com/client/v4"

if [ -z "$API_TOKEN" ]; then
  bashio::log.error "O API Token da Cloudflare não está configurado."
  exit 1
fi

get_public_ip() {
  curl -4 -fsS --max-time 15 https://api.ipify.org
}

is_proxied() {
  local domain="$1"
  local item
  IFS=',' read -ra items <<< "$PROXIED_DOMAINS"
  for item in "${items[@]}"; do
    item="$(echo "$item" | xargs)"
    [ "$item" = "$domain" ] && return 0
  done
  return 1
}

update_domain() {
  local domain="$1"
  local ip="$2"
  local zone
  local zone_id
  local record
  local record_id
  local current_ip
  local current_proxied
  local wanted_proxied
  local payload
  local response

  zone="${domain#*.}"

  zone_id="$(
    curl -fsS --max-time 15 \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      "${API}/zones?name=${zone}" |
      jq -r '.result[0].id // empty'
  )"

  if [ -z "$zone_id" ]; then
    bashio::log.error "Não foi possível encontrar a zona Cloudflare para ${domain}."
    return 1
  fi

  record="$(
    curl -fsS --max-time 15 \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      "${API}/zones/${zone_id}/dns_records?type=A&name=${domain}" 
  )"

  record_id="$(echo "$record" | jq -r '.result[0].id // empty')"
  current_ip="$(echo "$record" | jq -r '.result[0].content // empty')"
  current_proxied="$(echo "$record" | jq -r '.result[0].proxied // false')"

  if is_proxied "$domain"; then
    wanted_proxied="true"
  else
    wanted_proxied="false"
  fi

  if [ -z "$record_id" ]; then
    bashio::log.info "A criar registo A ${domain} -> ${ip} (proxied=${wanted_proxied})"

    payload="$(
      jq -n \
        --arg type "A" \
        --arg name "$domain" \
        --arg content "$ip" \
        --argjson ttl "$TTL" \
        --argjson proxied "$wanted_proxied" \
        '{type:$type,name:$name,content:$content,ttl:$ttl,proxied:$proxied}'
    )"

    response="$(
      curl -fsS --max-time 15 -X POST \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "$payload" \
        "${API}/zones/${zone_id}/dns_records"
    )"

    if [ "$(echo "$response" | jq -r '.success')" != "true" ]; then
      bashio::log.error "Erro ao criar ${domain}: $(echo "$response" | jq -c '.errors')"
      return 1
    fi

    bashio::log.info "${domain} criado com sucesso."
    return 0
  fi

  if [ "$current_ip" = "$ip" ] && [ "$current_proxied" = "$wanted_proxied" ]; then
    bashio::log.info "${domain} está atualizado: ${ip}, proxied=${wanted_proxied}"
    return 0
  fi

  bashio::log.info "A atualizar ${domain}: ${current_ip} -> ${ip}, proxied=${current_proxied} -> ${wanted_proxied}"

  payload="$(
    jq -n \
      --arg type "A" \
      --arg name "$domain" \
      --arg content "$ip" \
      --argjson ttl "$TTL" \
      --argjson proxied "$wanted_proxied" \
      '{type:$type,name:$name,content:$content,ttl:$ttl,proxied:$proxied}'
  )"

  response="$(
    curl -fsS --max-time 15 -X PUT \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "$payload" \
      "${API}/zones/${zone_id}/dns_records/${record_id}"
  )"

  if [ "$(echo "$response" | jq -r '.success')" != "true" ]; then
    bashio::log.error "Erro ao atualizar ${domain}: $(echo "$response" | jq -c '.errors')"
    return 1
  fi

  bashio::log.info "${domain} atualizado com sucesso."
}

run_update() {
  local ip
  ip="$(get_public_ip || true)"

  if [ -z "$ip" ]; then
    bashio::log.error "Não foi possível obter o IP público."
    return 1
  fi

  bashio::log.info "IP público atual: ${ip}"

  local domain
  IFS=',' read -ra domains <<< "$DOMAINS"

  for domain in "${domains[@]}"; do
    domain="$(echo "$domain" | xargs)"
    [ -z "$domain" ] && continue
    update_domain "$domain" "$ip" || true
  done
}

bashio::log.info "Cloudflare DDNS iniciado."
bashio::log.info "Domínios: ${DOMAINS}"
bashio::log.info "Proxy: ${PROXIED_DOMAINS}"
bashio::log.info "Intervalo: ${INTERVAL}"

run_update

while true; do
  sleep_seconds=300

  case "$INTERVAL" in
    *s) sleep_seconds="${INTERVAL%s}" ;;
    *m) sleep_seconds=$(( ${INTERVAL%m} * 60 )) ;;
    *h) sleep_seconds=$(( ${INTERVAL%h} * 3600 )) ;;
    *)  sleep_seconds=300 ;;
  esac

  sleep "$sleep_seconds"
  run_update
done
