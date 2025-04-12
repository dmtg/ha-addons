#!/bin/bash

# Carregar as opções do arquivo options.json
ALLOWED_HOSTS=$(jq -r '.HOMEPAGE_ALLOWED_HOSTS' /data/options.json)

# Se não for definida, usar o valor padrão "*"
ALLOWED_HOSTS="${ALLOWED_HOSTS:-*}"

# Verifica se o hostname foi corretamente passado
HOSTNAME=${HOSTNAME:-"localhost"}  # Se não houver HOSTNAME, define um valor padrão

# Imprimir as variáveis para verificação
echo "Allowed hosts are set to: ${ALLOWED_HOSTS}"
echo "Using hostname: ${HOSTNAME}"

# Exemplo de usar a variável em outro comando (por exemplo, no node server)
# node /app/server.js --allowed-hosts="${ALLOWED_HOSTS}"

# Ou outro comando necessário
exec "$@"

