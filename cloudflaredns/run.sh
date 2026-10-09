#!/usr/bin/env bash

set -uo pipefail

CONFIG="/data/options.json"

log() {
    echo "[$(date '+%d/%m/%Y %H:%M:%S')] [Cloudflare DDNS] $1"
}

# Ler configuração
API_TOKEN="$(jq -r '.cloudflare_api_token // ""' "$CONFIG")"
DOMAINS="$(jq -r '.ip4_domains // ""' "$CONFIG")"
IP6_DOMAINS="$(jq -r '.ip6_domains // ""' "$CONFIG")"
IP6_HOSTID="$(jq -r '.ip6_hostid // ""' "$CONFIG")"
IP6_PROVIDER="$(jq -r '.ip6_provider // "none"' "$CONFIG")"

# Aceitar configuração nova "proxied_domains" e antiga "proxied"
PROXIED_DOMAINS="$(jq -r '.proxied_domains // ""' "$CONFIG")"
if [ -z "$PROXIED_DOMAINS" ]; then
    PROXIED_DOMAINS="$(jq -r '.proxied // ""' "$CONFIG")"
fi

UPDATE_INTERVAL="$(jq -r '.update_cron // .update_interval // "5m"' "$CONFIG")"
TTL="$(jq -r '.ttl // 1' "$CONFIG")"

# Notificações Telegram (opcionais)
TELEGRAM_ENABLED="$(jq -r '.telegram_enabled // false' "$CONFIG")"
TELEGRAM_BOT_TOKEN="$(jq -r '.telegram_bot_token // ""' "$CONFIG")"
TELEGRAM_CHAT_ID="$(jq -r '.telegram_chat_id // ""' "$CONFIG")"
TELEGRAM_TEST_ON_START="$(jq -r '.telegram_test_on_start // false' "$CONFIG")"

notify_telegram() {
    local message="$1"
    local response

    [ "$TELEGRAM_ENABLED" = "true" ] || return 0

    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        log "AVISO: Telegram ativo, mas falta o token ou o Chat ID."
        return 0
    fi

    # Uma falha no Telegram nunca deve parar o DDNS.
    if ! response="$(curl -fsS --connect-timeout 5 --max-time 10 \
        -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${message}" 2>/dev/null)"; then
        log "AVISO: Não foi possível enviar a notificação Telegram."
        return 0
    fi

    if [ "$(printf '%s' "$response" | jq -r '.ok // false' 2>/dev/null)" != "true" ]; then
        log "AVISO: O Telegram não confirmou o envio da notificação."
    fi
    return 0
}

# Teste opcional das notificações Telegram no arranque
if [ "$TELEGRAM_TEST_ON_START" = "true" ]; then
    notify_telegram "✅ Cloudflare DDNS: teste de notificações Telegram concluído."
fi

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
log "Domínios IPv6: $IP6_DOMAINS"
log "Provedor IPv6: $IP6_PROVIDER"
log "Host ID IPv6: $IP6_HOSTID"
log "Intervalo: $UPDATE_INTERVAL"
log "TTL: $TTL"

# Obter IP público IPv4
get_public_ip() {
    curl -4 -fsS --connect-timeout 5 --max-time 15 \
        https://cloudflare.com/cdn-cgi/trace |
        awk -F= '$1=="ip"{print $2}'
}

# Obter IPv6 público
get_public_ipv6() {
    case "$IP6_PROVIDER" in
        none|disabled|"")
            return 0
            ;;
        cloudflare.trace)
            curl -6 -fsS --connect-timeout 5 --max-time 15 \
                https://cloudflare.com/cdn-cgi/trace |
                awk -F= '$1=="ip"{print $2}'
            ;;
        *)
            log "AVISO: Provedor IPv6 '$IP6_PROVIDER' não suportado."
            return 0
            ;;
    esac
}

# Construir IPv6 do destino a partir do prefixo /64 e host ID
build_ipv6() {
    local public_ipv6="$1"
    local hostid="$2"
    local prefix

    hostid="$(echo "$hostid" | sed 's/^:://')"

    if ! echo "$hostid" | grep -Eq '^([0-9A-Fa-f]{1,4}:){3}[0-9A-Fa-f]{1,4}$'; then
        log "ERRO: IP6_HOSTID inválido: $2"
        return 1
    fi

    prefix="$(echo "$public_ipv6" | cut -d: -f1-4)"

    if [ -z "$prefix" ] || [ "$(echo "$prefix" | awk -F: '{print NF}')" -ne 4 ]; then
        log "ERRO: Não foi possível obter o prefixo /64 de $public_ipv6"
        return 1
    fi

    echo "$prefix:$hostid"
}

# Obter nome da zona (compatível com domínios de dois níveis, como example.com)
get_zone_name() {
    local domain="$1"
    echo "$domain" | awk -F. '{print $(NF-1)"."$NF}'
}

# Obter Zone ID
get_zone_id() {
    local zone="$1"
    curl -fsS --connect-timeout 5 --max-time 20 \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" |
        jq -r '.result[0].id // empty'
}

# Verificar se o domínio deve ser PROXIED
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

    if echo "$PROXIED_DOMAINS" | grep -Fq "is($domain)"; then
        return 0
    fi

    return 1
}

# Atualizar um domínio IPv4
update_domain() {
    local domain="$1"
    local ip="$2"
    local zone zone_id record record_id current_ip current_proxied wanted_proxied
    local payload response

    zone="$(get_zone_name "$domain")"
    if ! zone_id="$(get_zone_id "$zone")" || [ -z "$zone_id" ]; then
        log "ERRO: Não foi possível obter a Zone ID para $domain ($zone)."
        return 1
    fi

    if is_proxied "$domain"; then
        wanted_proxied="true"
    else
        wanted_proxied="false"
    fi

    if ! record="$(curl -fsS --connect-timeout 5 --max-time 20 \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$domain")"; then
        log "ERRO: Não foi possível consultar o registo A de $domain."
        return 1
    fi

    record_id="$(echo "$record" | jq -r '.result[0].id // empty')"
    current_ip="$(echo "$record" | jq -r '.result[0].content // empty')"
    current_proxied="$(echo "$record" | jq -r '.result[0].proxied // false')"

    if [ "$current_ip" = "$ip" ] && [ "$current_proxied" = "$wanted_proxied" ]; then
        log "$domain está atualizado: $ip, proxied=$wanted_proxied"
        return 0
    fi

    log "A atualizar $domain: $current_ip -> $ip, proxied=$current_proxied -> $wanted_proxied"

    payload="$(jq -n \
        --arg type "A" \
        --arg name "$domain" \
        --arg content "$ip" \
        --argjson ttl "$TTL" \
        --argjson proxied "$wanted_proxied" \
        '{type:$type,name:$name,content:$content,ttl:$ttl,proxied:$proxied}')"

    if [ -n "$record_id" ]; then
        if ! response="$(curl -fsS --connect-timeout 5 --max-time 20 -X PUT \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
            --data "$payload")"; then
            log "ERRO: Falha ao atualizar o registo A de $domain."
            return 1
        fi
    else
        if ! response="$(curl -fsS --connect-timeout 5 --max-time 20 -X POST \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
            --data "$payload")"; then
            log "ERRO: Falha ao criar o registo A de $domain."
            return 1
        fi
    fi

    if [ "$(echo "$response" | jq -r '.success // false')" != "true" ]; then
        log "ERRO: Cloudflare não confirmou a atualização de $domain."
        echo "$response"
        return 1
    fi

    log "$domain atualizado com sucesso: $ip, proxied=$wanted_proxied"
    notify_telegram "✅ Cloudflare DDNS: domínio $domain atualizado para $ip."
    return 0
}

# Atualizar um registo AAAA
update_domain6() {
    local domain="$1"
    local ip="$2"
    local zone zone_id record record_id current_ip current_proxied wanted_proxied
    local payload response

    zone="$(get_zone_name "$domain")"
    if ! zone_id="$(get_zone_id "$zone")" || [ -z "$zone_id" ]; then
        log "ERRO: Não foi possível obter a Zone ID para IPv6 de $domain ($zone)."
        return 1
    fi

    if is_proxied "$domain"; then
        wanted_proxied="true"
    else
        wanted_proxied="false"
    fi

    if ! record="$(curl -fsS --connect-timeout 5 --max-time 20 \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA&name=$domain")"; then
        log "ERRO: Não foi possível consultar o registo AAAA de $domain."
        return 1
    fi

    record_id="$(echo "$record" | jq -r '.result[0].id // empty')"
    current_ip="$(echo "$record" | jq -r '.result[0].content // empty')"
    current_proxied="$(echo "$record" | jq -r '.result[0].proxied // false')"

    if [ "$current_ip" = "$ip" ] && [ "$current_proxied" = "$wanted_proxied" ]; then
        log "$domain AAAA está atualizado: $ip, proxied=$wanted_proxied"
        return 0
    fi

    log "A atualizar AAAA $domain: $current_ip -> $ip, proxied=$current_proxied -> $wanted_proxied"

    payload="$(jq -n \
        --arg type "AAAA" \
        --arg name "$domain" \
        --arg content "$ip" \
        --argjson ttl "$TTL" \
        --argjson proxied "$wanted_proxied" \
        '{type:$type,name:$name,content:$content,ttl:$ttl,proxied:$proxied}')"

    if [ -n "$record_id" ]; then
        if ! response="$(curl -fsS --connect-timeout 5 --max-time 20 -X PUT \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
            --data "$payload")"; then
            log "ERRO: Falha ao atualizar o registo AAAA de $domain."
            return 1
        fi
    else
        if ! response="$(curl -fsS --connect-timeout 5 --max-time 20 -X POST \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
            --data "$payload")"; then
            log "ERRO: Falha ao criar o registo AAAA de $domain."
            return 1
        fi
    fi

    if [ "$(echo "$response" | jq -r '.success // false')" != "true" ]; then
        log "ERRO: Cloudflare não confirmou a atualização AAAA de $domain."
        echo "$response"
        return 1
    fi

    log "$domain AAAA atualizado com sucesso: $ip, proxied=$wanted_proxied"
    notify_telegram "✅ Cloudflare DDNS: domínio $domain atualizado para IPv6 $ip."
    return 0
}

# Atualizar todos os domínios IPv6
update_all_ipv6() {
    [ -z "$IP6_DOMAINS" ] && return 0
    [ "$IP6_PROVIDER" = "none" ] && return 0
    [ "$IP6_PROVIDER" = "disabled" ] && return 0

    local public_ipv6 domain target_ipv6 result=0
    if ! public_ipv6="$(get_public_ipv6)" || [ -z "$public_ipv6" ]; then
        log "AVISO: Não foi possível obter o IPv6 público. IPv6 não atualizado."
        notify_telegram "⚠️ Cloudflare DDNS: não foi possível detetar o IPv6 público. Os registos existentes foram preservados."
        return 0
    fi

    log "IPv6 público detetado: $public_ipv6"
    IFS=',' read -ra DOMAIN6_ARRAY <<< "$IP6_DOMAINS"

    for domain in "${DOMAIN6_ARRAY[@]}"; do
        domain="$(echo "$domain" | xargs)"
        [ -z "$domain" ] && continue

        if [ -z "$IP6_HOSTID" ]; then
            log "ERRO: IP6_HOSTID não configurado para $domain."
            result=1
            continue
        fi

        if ! target_ipv6="$(build_ipv6 "$public_ipv6" "$IP6_HOSTID")"; then
            result=1
            continue
        fi

        if ! update_domain6 "$domain" "$target_ipv6"; then
            result=1
        fi
    done

    return "$result"
}

# Atualizar todos os domínios
update_all() {
    local ip domain result=0

    if ! ip="$(get_public_ip)" || [ -z "$ip" ]; then
        log "ERRO: Não foi possível obter o IP público IPv4. Os registos DNS foram preservados."
        notify_telegram "⚠️ Cloudflare DDNS: falha ao detetar o IPv4 público. Os registos existentes foram preservados."
        return 1
    fi

    log "IP público atual: $ip"
    IFS=',' read -ra DOMAIN_ARRAY <<< "$DOMAINS"

    for domain in "${DOMAIN_ARRAY[@]}"; do
        domain="$(echo "$domain" | xargs)"
        [ -z "$domain" ] && continue
        if ! update_domain "$domain" "$ip"; then
            result=1
        fi
    done

    if ! update_all_ipv6; then
        result=1
    fi

    return "$result"
}

# Converter intervalo para segundos
interval_to_seconds() {
    local value="$1"
    value="${value#@every }"

    case "$value" in
        *s) echo "${value%s}" ;;
        *m) echo "$(( ${value%m} * 60 ))" ;;
        *h) echo "$(( ${value%h} * 3600 ))" ;;
        *)  echo "$value" ;;
    esac
}

# Definir intervalo
SLEEP_SECONDS="$(interval_to_seconds "$UPDATE_INTERVAL")"
if ! [[ "$SLEEP_SECONDS" =~ ^[0-9]+$ ]] || [ "$SLEEP_SECONDS" -lt 1 ]; then
    log "AVISO: Intervalo inválido '$UPDATE_INTERVAL'. A usar 300 segundos."
    SLEEP_SECONDS=300
fi

# Notificar encerramento de forma controlada
shutdown_handler() {
    log "A encerrar Cloudflare DDNS."
    exit 0
}
trap shutdown_handler TERM INT

# Atualização inicial: falhas não terminam o processo
if ! update_all; then
    log "AVISO: A atualização inicial falhou. O serviço continuará ativo."
fi

log "Próxima atualização em $SLEEP_SECONDS segundos."

# Ciclo principal: falhas são registadas e tentadas novamente no ciclo seguinte
while true; do
    sleep "$SLEEP_SECONDS"
    if ! update_all; then
        log "AVISO: A atualização falhou. Nova tentativa em $SLEEP_SECONDS segundos."
    fi
done
