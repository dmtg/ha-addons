#!/usr/bin/env bash

set -e

CONFIG="/data/options.json"

log() {
    echo "[Cloudflare DDNS] $1"
}

# Ler configuração
API_TOKEN="$(jq -r '.cloudflare_api_token // ""' "$CONFIG")"
DOMAINS="$(jq -r '.ip4_domains // ""' "$CONFIG")"
PROXIED_DOMAINS="$(jq -r '.proxied_domains // ""' "$CONFIG")"
UPDATE_INTERVAL="$(jq -r '.update_interval // "5m"' "$CONFIG")"
TTL="$(jq -r '.ttl // 1' "$CONFIG")"

if [ -z "$API_TOKEN" ]; then
    log "ERRO: Cloudflare API Token não configurado."
    exit 1
fi

if [ -z "$DOMAINS" ]; then
    log "ERRO: Nenhum domínio configurado."
    exit 1
fi

log "Cloudflare DDNS iniciado."
log "Domínios: $DOMAINS"
log "Domínios proxied: $PROXIED_DOMAINS"
log "Intervalo: $UPDATE_INTERVAL"
log "TTL: $TTL"

get_public_ip() {
    curl -4 -fsS https://cloudflare.com/cdn-cgi/trace \
        | awk -F= '$1=="ip"{print $2}'
}

get_zone_name() {
    local domain="$1"
    echo "$domain" | awk -F. '{print $(NF-1)"."$NF}'
}

get_zone_id() {
    local zone="$1"

    curl -fsS \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" \
        | jq -r '.result[0].id // empty'
}

is_proxied() {
    local domain="$1"
    local item

    IFS=',' read -ra PROXY_ARRAY <<< "$PROXIED_DOMAINS"

    for item in "${PROXY_ARRAY[@]}"; do
        item="$(echo "$item" | xargs)"
        if [ "$item" = "$domain" ]; then
            return 0
        fi
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

    zone="$(get_zone_name "$domain")"
    zone_id="$(get_zone_id "$zone")"

    if [ -z "$zone_id" ]; then
        log "ERRO: Não foi possível obter a Zone ID para $domain ($zone)."
        return 1
    fi

    if is_proxied "$domain"; then
        wanted_proxied="true"
    else
        wanted_proxied="false"
    fi

    record="$(
        curl -fsS \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$domain"
    )"

    record_id="$(echo "$record" | jq -r '.result[0].id // empty')"
    current_ip="$(echo "$record" | jq -r '.result[0].content // empty')"
    current_proxied="$(echo "$record" | jq -r '.result[0].proxied // false')"

    if [ "$current_ip" = "$ip" ] && [ "$current_proxied" = "$wanted_proxied" ]; then
        log "$domain está atualizado: $ip, proxied=$wanted_proxied"
        return 0
    fi

    log "A atualizar $domain: $current_ip -> $ip, proxied=$current_proxied -> $wanted_proxied"

    payload="$(
        jq -n \
            --arg type "A" \
            --arg name "$domain" \
            --arg content "$ip" \
            --argjson ttl "$TTL" \
            --argjson proxied "$wanted_proxied" \
            '{
                type: $type,
                name: $name,
                content: $content,
                ttl: $ttl,
                proxied: $proxied
            }'
    )"

    if [ -n "$record_id" ]; then
        response="$(
            curl -fsS -X PUT \
                -H "Authorization: Bearer $API_TOKEN" \
                -H "Content-Type: application/json" \
                "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
                --data "$payload"
        )"
    else
        response="$(
            curl -fsS -X POST \
                -H "Authorization: Bearer $API_TOKEN" \
                -H "Content-Type: application/json" \
                "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
                --data "$payload"
        )"
    fi

    if [ "$(echo "$response" | jq -r '.success // false')" != "true" ]; then
        log "ERRO: Cloudflare não confirmou a atualização de $domain."
        echo "$response"
        return 1
    fi

    log "$domain atualizado com sucesso: $ip, proxied=$wanted_proxied"
}

update_all() {
    local ip
    ip="$(get_public_ip)"

    if [ -z "$ip" ]; then
        log "ERRO: Não foi possível obter o IP público."
        return 1
    fi

    log "IP público atual: $ip"

    IFS=',' read -ra DOMAIN_ARRAY <<< "$DOMAINS"

    for domain in "${DOMAIN_ARRAY[@]}"; do
        domain="$(echo "$domain" | xargs)"
        [ -z "$domain" ] && continue
        update_domain "$domain" "$ip"
    done
}

# Primeira atualização
update_all

# Converter intervalos simples como 5m, 10m, 1h para segundos
interval_to_seconds() {
    local value="$1"

    case "$value" in
        *s) echo "${value%s}" ;;
        *m) echo "$(( ${value%m} * 60 ))" ;;
        *h) echo "$(( ${value%h} * 3600 ))" ;;
        *)  echo "$value" ;;
    esac
}

SLEEP_SECONDS="$(interval_to_seconds "$UPDATE_INTERVAL")"

if ! [[ "$SLEEP_SECONDS" =~ ^[0-9]+$ ]] || [ "$SLEEP_SECONDS" -lt 1 ]; then
    log "AVISO: Intervalo inválido '$UPDATE_INTERVAL'. A usar 300 segundos."
    SLEEP_SECONDS=300
fi

while true; do
    sleep "$SLEEP_SECONDS"
    update_all
done
