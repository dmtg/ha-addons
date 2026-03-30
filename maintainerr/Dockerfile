FROM ghcr.io/maintainerr/maintainerr:latest

WORKDIR /opt/data
# Copy data for add-on
COPY run.sh /opt/data/scripts/
RUN chmod a+x /opt/data/scripts/run.sh

CMD [ "/opt/data/scripts/run.sh" ]
