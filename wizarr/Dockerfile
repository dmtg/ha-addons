FROM ghcr.io/wizarrrr/wizarr:latest

RUN mkdir /app/config
# Copy data for add-on
COPY run.sh /app/scripts/
RUN chmod a+x /app/scripts/run.sh

CMD [ "/app/scripts/run.sh" ]
