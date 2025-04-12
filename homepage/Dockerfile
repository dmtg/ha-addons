FROM ghcr.io/gethomepage/homepage:latest

# Instalar jq para ler options.json
RUN apk add --no-cache jq

RUN mkdir /app/config
COPY run.sh /app/scripts/
RUN chmod a+x /app/scripts/run.sh

CMD [ "/app/scripts/run.sh" ]
