#!/usr/bin/env bash

set -e

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

# Aceita a configuração nova "proxied_domains"
PROXIED_DOMAINS="$(jq -r '.proxied_domains // ""' "$CONFIG")"

# Se não existir, aceita a configuração antiga "proxied"
if [ -z "$PROXIED_DOMAINS" ]; then
    PROXIED_DOMAINS="$(jq -r '.proxied // ""' "$CONFIG")"
fi

UPDATE_INTERVAL="$(jq -r '.update_cron // .update_interval // "5m"' "$CONFIG")"
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
log "Domínios IPv6: $IP6_DOMAINS"
log "Provedor IPv6: $IP6_PROVIDER"
log "Host ID IPv6: $IP6_HOSTID"
log "Intervalo: $UPDATE_INTERVAL"
log "TTL: $TTL"


# ---------------------------------------------------------
# Obter IP público
# ---------------------------------------------------------

get_public_ip() {
    curl -4 -fsS https://cloudflare.com/cdn-cgi/trace |
        awk -F= '$1=="ip"{print $2}'
}


# ---------------------------------------------------------
# Obter IPv6 público
# ---------------------------------------------------------

get_public_ipv6() {

    case "$IP6_PROVIDER" in
        none|disabled|"")
            return 0
            ;;
        cloudflare.trace)
            curl -6 -fsS https://cloudflare.com/cdn-cgi/trace |
                awk -F= '$1=="ip"{print $2}'
            ;;
        *)
            log "AVISO: Provedor IPv6 '$IP6_PROVIDER' não suportado.
"
            return 0
            ;;
    esac
}


# ---------------------------------------------------------
# Construir IPv6 do destino a partir do prefixo /64 e host ID
# Exemplo:
# 2001:8a0:601c:7b00 + f22f:74ff:feae:a1c4
# ---------------------------------------------------------

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


# ---------------------------------------------------------
# Obter nome da zona
# Exemplo:
# app.xavelha.top -> xavelha.top
# ---------------------------------------------------------

get_zone_name() {
    local domain="$1"

    echo "$domain" |
        awk -F. '{print $(NF-1)"."$NF}'
}


# ---------------------------------------------------------
# Obter Zone ID
# ---------------------------------------------------------

get_zone_id() {
    local zone="$1"

    curl -fsS \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" |
        jq -r '.result[0].id // empty'
}


# ---------------------------------------------------------
# Verificar se o domínio deve ser PROXIED
#
# Aceita:
#
# micro.xavelha.top,canico.xavelha.top
#
# ou:
#
# is(micro.xavelha.top) || is(canico.xavelha.top)
# ---------------------------------------------------------

is_proxied() {

    local domain="$1"
    local item

    # Primeiro verifica formato:
    #
    # micro.xavelha.top,canico.xavelha.top

    IFS=',' read -ra PROXY_ARRAY <<< "$PROXIED_DOMAINS"

    for item in "${PROXY_ARRAY[@]}"; do

        item="$(echo "$item" | xargs)"

        if [ "$item" = "$domain" ]; then
            return 0
        fi

    done


    # Depois verifica o formato antigo:
    #
    # is(micro.xavelha.top) || is(canico.xavelha.top)

    if echo "$PROXIED_DOMAINS" | grep -Fq "is($domain)"; then
        return 0
    fi


    return 1
}


# ---------------------------------------------------------
# Atualizar um domínio
# ---------------------------------------------------------

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


    # Determinar se deve usar Cloudflare Proxy

    if is_proxied "$domain"; then

        wanted_proxied="true"

    else

        wanted_proxied="false"

    fi


    # Obter registo A existente

    record="$(
        curl -fsS \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$domain"
    )"


    record_id="$(
        echo "$record" |
        jq -r '.result[0].id // empty'
    )"


    current_ip="$(
        echo "$record" |
        jq -r '.result[0].content // empty'
    )"


    current_proxied="$(
        echo "$record" |
        jq -r '.result[0].proxied // false'
    )"


    # Se já estiver tudo correto, não fazer nada

    if [ "$current_ip" = "$ip" ] &&
       [ "$current_proxied" = "$wanted_proxied" ]; then

        log "$domain está atualizado: $ip, proxied=$wanted_proxied"

        return 0

    fi


    log "A atualizar $domain: $current_ip -> $ip, proxied=$current_proxied -> $wanted_proxied"


    # Criar JSON

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


    # Atualizar registo existente

    if [ -n "$record_id" ]; then

        response="$(
            curl -fsS -X PUT \
                -H "Authorization: Bearer $API_TOKEN" \
                -H "Content-Type: application/json" \
                "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
                --data "$payload"
        )"


    # Criar registo se não existir

    else

        response="$(
            curl -fsS -X POST \
                -H "Authorization: Bearer $API_TOKEN" \
                -H "Content-Type: application/json" \
                "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
                --data "$payload"
        )"

    fi


    # Confirmar resposta Cloudflare

    if [ "$(echo "$response" | jq -r '.success // false')" != "true" ]; then

        log "ERRO: Cloudflare não confirmou a atualização de $domain."

        echo "$response"

        return 1

    fi


    log "$domain atualizado com sucesso: $ip, proxied=$wanted_proxied"
}


# ---------------------------------------------------------
# Atualizar um registo AAAA
# ---------------------------------------------------------

update_domain6() {

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

    zone="$(get_zone_name "$domain")"
    zone_id="$(get_zone_id "$zone")"

    if [ -z "$zone_id" ]; then
        log "ERRO: Não foi possível obter a Zone ID para IPv6 de $domain ($zone)."
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
            "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA&name=$domain"
    )"

    record_id="$(echo "$record" | jq -r '.result[0].id // empty')"
    current_ip="$(echo "$record" | jq -r '.result[0].content // empty')"
    current_proxied="$(echo "$record" | jq -r '.result[0].proxied // false')"

    if [ "$current_ip" = "$ip" ] && [ "$current_proxied" = "$wanted_proxied" ]; then
        log "$domain AAAA está atualizado: $ip, proxied=$wanted_proxied"
        return 0
    fi

    log "A atualizar AAAA $domain: $current_ip -> $ip, proxied=$current_proxied -> $wanted_proxied"

    payload="$(
        jq -n \
            --arg type "AAAA" \
            --arg name "$domain" \
            --arg content "$ip" \
            --argjson ttl "$TTL" \
            --argjson proxied "$wanted_proxied" \
            '{type:$type,name:$name,content:$content,ttl:$ttl,proxied:$proxied}'
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
        log "ERRO: Cloudflare não confirmou a atualização AAAA de $domain."
        echo "$response"
        return 1
    fi

    log "$domain AAAA atualizado com sucesso: $ip, proxied=$wanted_proxied"
}


# ---------------------------------------------------------
# Atualizar todos os domínios IPv6
# ---------------------------------------------------------

update_all_ipv6() {

    [ -z "$IP6_DOMAINS" ] && return 0
    [ "$IP6_PROVIDER" = "none" ] && return 0

    local public_ipv6
    public_ipv6="$(get_public_ipv6)"

    if [ -z "$public_ipv6" ]; then
        log "AVISO: Não foi possível obter o IPv6 público. IPv6 não atualizado."
        return 0
    fi

    log "IPv6 público detetado: $public_ipv6"

    IFS=',' read -ra DOMAIN6_ARRAY <<< "$IP6_DOMAINS"

    for domain in "${DOMAIN6_ARRAY[@]}"; do
        domain="$(echo "$domain" | xargs)"
        [ -z "$domain" ] && continue

        if [ -z "$IP6_HOSTID" ]; then
            log "ERRO: IP6_HOSTID não configurado para $domain."
            continue
        fi

        local target_ipv6
        target_ipv6="$(build_ipv6 "$public_ipv6" "$IP6_HOSTID")" || continue
        update_domain6 "$domain" "$target_ipv6"
    done
}


# ---------------------------------------------------------
# Atualizar todos os domínios
# ---------------------------------------------------------

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

    update_all_ipv6
}


# ---------------------------------------------------------
# Primeira atualização
# ---------------------------------------------------------

update_all


# ---------------------------------------------------------
# Converter intervalo para segundos
#
# 5m = 300
# 10m = 600
# 1h = 3600
# ---------------------------------------------------------

interval_to_seconds() {

    local value="$1"

    # Aceita o formato Go duration usado na configuração do add-on:
    # "@every 5m". O prefixo @every é ignorado para o sleep local.
    value="${value#@every }"

    case "$value" in

        *s)
            echo "${value%s}"
            ;;

        *m)
            echo "$(( ${value%m} * 60 ))"
            ;;

        *h)
            echo "$(( ${value%h} * 3600 ))"
            ;;

        *)
            echo "$value"
            ;;

    esac
}


SLEEP_SECONDS="$(interval_to_seconds "$UPDATE_INTERVAL")"


if ! [[ "$SLEEP_SECONDS" =~ ^[0-9]+$ ]] ||
   [ "$SLEEP_SECONDS" -lt 1 ]; then

    log "AVISO: Intervalo inválido '$UPDATE_INTERVAL'. A usar 300 segundos."

    SLEEP_SECONDS=300

fi


log "Próxima atualização em $SLEEP_SECONDS segundos."


# ---------------------------------------------------------
# Loop
# ---------------------------------------------------------

while true; do

    sleep "$SLEEP_SECONDS"

    update_all

done
