FROM ghcr.io/gethomepage/homepage:latest

# Instalar jq para ler options.json
RUN apk add --no-cache jq

# Definir o HOSTNAME como uma variável de ambiente
ENV HOSTNAME=localhost

RUN mkdir /app/config
COPY run.sh /app/scripts/
RUN chmod a+x /app/scripts/run.sh

CMD [ "/app/scripts/run.sh" ]
