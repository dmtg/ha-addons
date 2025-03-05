FROM registry.hub.docker.com/petersem/posterr:latest

RUN mkdir /usr/src/app/config
# Copy data for add-on
COPY run.sh /usr/src/app/scripts/
RUN chmod a+x /usr/src/app/scripts/run.sh

CMD [ "/usr/src/app/scripts/run.sh" ]
