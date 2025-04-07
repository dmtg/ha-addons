#!/bin/bash

# Verificar se a variável HOMEPAGE_ALLOWED_HOSTS está definida, se não, usar o valor padrão "*"
ALLOWED_HOSTS="${HOMEPAGE_ALLOWED_HOSTS:-*}"

# Imprimir o valor para verificação
echo "Allowed hosts are set to: ${ALLOWED_HOSTS}"

# Aqui, você pode usar a variável $ALLOWED_HOSTS no seu código, por exemplo, configurando o seu aplicativo
# Iniciar o servidor ou aplicativo com o valor configurado para allowed hosts
# Dependendo da estrutura do seu código, você pode passar a variável para o seu app
# Exemplo:
# node /app/server.js --allowed-hosts=${ALLOWED_HOSTS}

# Ou executar outro comando necessário
exec "$@"
