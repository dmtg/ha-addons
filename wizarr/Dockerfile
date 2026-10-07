FROM ghcr.io/wizarrrr/wizarr:latest

# Guardar o entrypoint original do Wizarr
RUN cp /usr/local/bin/docker-entrypoint.sh /usr/local/bin/wizarr-entrypoint-original.sh

# Colocar o nosso entrypoint
COPY run.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
