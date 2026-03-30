FROM ghcr.io/maintainerr/maintainerr:latest

USER root

# copiar script de arranque
COPY run.sh /run.sh

# não usamos chmod para evitar erros
# vamos executar com sh diretamente
USER 1003

CMD ["sh", "/run.sh"]
