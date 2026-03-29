FROM ghcr.io/maintainerr/maintainerr:latest

# Criar pasta persistente e garantir estrutura
RUN mkdir -p /share/maintainerr && \
    mkdir -p /opt && \
    rm -rf /opt/data && \
    ln -s /share/maintainerr /opt/data

# Definir permissões (importante para evitar problemas com PUID/PGID)
RUN chown -R 1000:1000 /share/maintainerr

# Variáveis de ambiente
ENV TZ=Europe/Lisbon

# Porta usada pela aplicação
EXPOSE 6246
