FROM registry.hub.docker.com/petersem/posterr:latest

RUN mkdir /src/app
# Copy data for add-on
COPY run.sh /app/scripts/
RUN chmod a+x /app/scripts/run.sh

CMD [ "/app/scripts/run.sh" ]
