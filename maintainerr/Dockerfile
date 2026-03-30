FROM ghcr.io/maintainerr/maintainerr:latest

# mudar para root para poder copiar e dar permissões
USER root

COPY run.sh /run.sh
RUN chmod +x /run.sh

# voltar ao user original (1000 normalmente)
USER 1000

CMD ["/run.sh"]
