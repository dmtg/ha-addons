FROM ghcr.io/maintainerr/maintainerr:3.3.0
# Criar pasta persistente se não existir
RUN mkdir -p /share/maintainerr

# Garantir permissões
RUN chmod -R 777 /share/maintainerr
ln -s /share/maintainerr /opt/data
