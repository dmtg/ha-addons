FROM ghcr.io/gethomepage/homepage:latest

# Instalar jq (se ainda não estiver instalado)
RUN apk add --no-cache jq

# Criar o diretório onde o script será copiado
RUN mkdir -p /app/scripts

# Copiar o script run.sh para o diretório correto
COPY run.sh /app/scripts/run.sh

# Garantir que o script tenha permissões de execução
RUN chmod a+x /app/scripts/run.sh

# Definir o script como o comando principal ao iniciar o contêiner
CMD ["/app/scripts/run.sh"]
