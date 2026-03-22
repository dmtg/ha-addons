FROM ghcr.io/wizarrrr/wizarr:latest

WORKDIR /data
# Copy data for add-on
COPY run.sh /data/scripts/
RUN chmod a+x /data/scripts/run.sh

CMD [ "/data/scripts/run.sh" ]
