FROM registry.hub.docker.com/rogerfar/rdtclient:latest

WORKDIR /app
# Copy data for add-on
COPY run.sh /app/scripts/
RUN chmod a+x /app/scripts/run.sh

CMD [ "/app/scripts/run.sh" ]
